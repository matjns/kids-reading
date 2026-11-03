import Foundation

public struct CatalogProblem: Error, Equatable, CustomStringConvertible, LocalizedError {
    public var messages: [String]

    public init(messages: [String]) {
        self.messages = messages
    }

    public var description: String {
        messages.joined(separator: "\n")
    }

    public var errorDescription: String? {
        description
    }
}

public enum CatalogLoader {
    public static func load(directory: URL) throws -> Catalog {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else {
            throw CatalogProblem(messages: ["Story folder not found at \(directory.path)."])
        }
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        if urls.isEmpty {
            throw CatalogProblem(messages: ["No story files were found in \(directory.path)."])
        }

        var passages: [Passage] = []
        var messages: [String] = []
        let decoder = JSONDecoder()
        for url in urls {
            let name = url.lastPathComponent
            do {
                let data = try Data(contentsOf: url)
                let decoded = try decodePassages(data: data, fileName: name, decoder: decoder)
                passages.append(contentsOf: decoded)
            } catch let problem as CatalogProblem {
                messages.append(contentsOf: problem.messages)
            } catch {
                messages.append("\(name): \(error)")
            }
        }

        if passages.isEmpty && messages.isEmpty {
            messages.append("The story files did not contain any stories.")
        }
        messages.append(contentsOf: validate(passages))
        if !messages.isEmpty {
            throw CatalogProblem(messages: messages)
        }
        return Catalog(passages: passages)
    }

    #if SWIFT_PACKAGE
    public static func loadBundled() throws -> Catalog {
        guard let resourceRoot = Bundle.module.resourceURL else {
            throw CatalogProblem(messages: ["The story bundle is missing."])
        }
        return try load(directory: resourceRoot.appendingPathComponent("Passages", isDirectory: true))
    }
    #endif

    static func decodePassages(data: Data, fileName: String, decoder: JSONDecoder) throws -> [Passage] {
        let json = try JSONSerialization.jsonObject(with: data)
        if json is [String: Any] {
            return [try decoder.decode(Passage.self, from: data)]
        }
        if json is [Any] {
            return try decoder.decode([Passage].self, from: data)
        }
        throw CatalogProblem(messages: ["\(fileName): a story file must be one story object or a list of stories."])
    }

    public static func validate(_ passages: [Passage]) -> [String] {
        var messages: [String] = []
        var seenIds = Set<String>()
        var seenTitles = Set<String>()
        var ordersByLevel: [Int: Set<Int>] = [:]

        for passage in passages {
            let label = passage.id.isEmpty ? "(missing id)" : passage.id
            if passage.id.isEmpty || !isKebab(passage.id) {
                messages.append("\(label): id must be lowercase words separated by hyphens.")
            }
            if !seenIds.insert(passage.id).inserted {
                messages.append("\(label): duplicate story id.")
            }
            let titleKey = passage.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if titleKey.isEmpty {
                messages.append("\(label): title is empty.")
            } else if !seenTitles.insert(titleKey).inserted {
                messages.append("\(label): duplicate title.")
            }
            if passage.level < TrailGuide.minimumLevel || passage.level > TrailGuide.maximumLevel {
                messages.append("\(label): level must be 1, 2, or 3.")
            }
            var orders = ordersByLevel[passage.level] ?? []
            if !orders.insert(passage.order).inserted {
                messages.append("\(label): another story on this trail already uses order \(passage.order).")
            }
            ordersByLevel[passage.level] = orders

            if passage.kind == .fable {
                let note = passage.attribution?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let lowered = note.lowercased()
                if note.isEmpty || !(lowered.contains("aesop") || lowered.contains("public domain")) {
                    messages.append("\(label): a fable needs an attribution that names Aesop or says it is public domain.")
                }
            }

            if passage.sentences.count < 3 {
                messages.append("\(label): needs at least 3 sentences or poem lines.")
            }
            var sentenceIds = Set<String>()
            for sentence in passage.sentences {
                if sentence.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    messages.append("\(label): sentence \(sentence.id) is empty.")
                }
                if sentence.id.isEmpty || !sentenceIds.insert(sentence.id).inserted {
                    messages.append("\(label): sentence ids must be unique and not empty.")
                }
            }

            if passage.questions.count < 3 || passage.questions.count > 5 {
                messages.append("\(label): needs 3 to 5 questions.")
            }
            var skills = Set<QuestionSkill>()
            var questionIds = Set<String>()
            var hasMainIdea = false
            for question in passage.questions {
                if !questionIds.insert(question.id).inserted || question.id.isEmpty {
                    messages.append("\(label): question ids must be unique and not empty.")
                }
                if !skills.insert(question.skill).inserted {
                    messages.append("\(label): skill \(question.skill.rawValue) is used more than once.")
                }
                if question.skill == .mainIdea { hasMainIdea = true }
                if question.prompt.trimmingCharacters(in: .whitespacesAndNewlines).count < 8 {
                    messages.append("\(label): question \(question.id) prompt is too short.")
                }
                if question.explanation.trimmingCharacters(in: .whitespacesAndNewlines).count < 40 {
                    messages.append("\(label): question \(question.id) explanation is too short.")
                }
                if question.choices.count < 3 || question.choices.count > 4 {
                    messages.append("\(label): question \(question.id) needs 3 or 4 choices.")
                }
                var choiceIds = Set<String>()
                var choiceTexts = Set<String>()
                for choice in question.choices {
                    if choice.id.isEmpty || !choiceIds.insert(choice.id).inserted {
                        messages.append("\(label): question \(question.id) has a duplicate or empty choice id.")
                    }
                    let textKey = choice.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if textKey.isEmpty || !choiceTexts.insert(textKey).inserted {
                        messages.append("\(label): question \(question.id) has a duplicate or empty choice.")
                    }
                }
                if !choiceIds.contains(question.answerId) {
                    messages.append("\(label): question \(question.id) answerId does not match a choice.")
                }
                if question.lookBackSentenceIds.isEmpty {
                    messages.append("\(label): question \(question.id) needs at least one look-back sentence.")
                }
                for sentenceId in question.lookBackSentenceIds where !sentenceIds.contains(sentenceId) {
                    messages.append("\(label): question \(question.id) looks back at missing sentence \(sentenceId).")
                }
            }
            if !hasMainIdea {
                messages.append("\(label): include one main idea question.")
            }

            let words = passage.wordCount
            if passage.kind == .poem {
                if words < 25 || words > 180 {
                    messages.append("\(label): poem has \(words) words; keep poems between 25 and 180.")
                }
            } else {
                switch passage.level {
                case 1 where words < 70 || words > 170:
                    messages.append("\(label): level 1 passage has \(words) words; aim for 70 to 170.")
                case 2 where words < 110 || words > 230:
                    messages.append("\(label): level 2 passage has \(words) words; aim for 110 to 230.")
                case 3 where words < 150 || words > 320:
                    messages.append("\(label): level 3 passage has \(words) words; aim for 150 to 320.")
                default:
                    break
                }
            }
        }
        return messages
    }

    private static func isKebab(_ value: String) -> Bool {
        guard !value.isEmpty, value.count <= 60 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        if value.rangeOfCharacter(from: allowed.inverted) != nil { return false }
        if value.hasPrefix("-") || value.hasSuffix("-") || value.contains("--") { return false }
        return true
    }
}
