//
//  File.swift
//
//
//  Created by Joshua on 1/1/21.
//

import Foundation

public class TextRank {
    public var pages: [(pageId: String, chunks: String)] = [(pageId: String, chunks: String)]() {
        didSet {
            textToSentences()
        }
    }
    
    public var chunks: [(pageId: String, chunks: [String])] = [(pageId: String, chunks: [String])]() {
        didSet {
            chunksToSentences()
        }
    }

    public var graph: TextGraph
    public var sentences = [Sentence]()
    public var summarizationFraction: Float = 0.2
    public var graphDamping: Float = 0.85
    public var stopwords = [String]() {
        didSet {
            textToSentences()
        }
    }

    public init() {
        pages = [("", "")]
        graph = TextGraph(damping: graphDamping)
    }

    public init(pages: [(pageId: String, chunks: String)]) {
        self.pages = pages
        graph = TextGraph(damping: graphDamping)
        textToSentences()
    }
    
    public init(chunksPerPage: [(pageId: String, chunks: [String])]) {
        self.chunks = chunksPerPage
        graph = TextGraph(damping: graphDamping)
        chunksToSentences()
    }

    public init(text: String) {
        self.pages = [("", text)]
        graph = TextGraph(damping: graphDamping)
        textToSentences()
    }

    public init(text: String, summarizationFraction: Float = 0.2, graphDamping: Float = 0.85) {
        self.pages = [("", text)]
        self.summarizationFraction = summarizationFraction
        self.graphDamping = graphDamping
        graph = TextGraph(damping: graphDamping)
        textToSentences()
    }

    func chunksToSentences() {
        sentences = []
        for (pageId, pageChunks) in chunks {
            for (chunkIndex, chunk) in pageChunks.enumerated() {
                sentences.append(
                    Sentence(text: chunk.trimmingCharacters(in: .whitespacesAndNewlines),
                             originalTextIndex: chunkIndex,
                             pageID: pageId,
                             additionalStopwords: stopwords)
                )
            }
        }
    }

    func textToSentences() {
        sentences = [];
        for (pageId, page) in pages {
            sentences.append(contentsOf: TextRank.splitIntoSentences(page, pageID: pageId, additionalStopwords: stopwords).filter { $0.length > 0 })
        }
    }
}

extension TextRank {
    public func runPageRank() throws -> TextGraph.PageRankResult {
        buildGraph()
        return try graph.runPageRank()
    }

    /// Build the TextGraph using the sentences as nodes.
    func buildGraph() {
        graph.clearGraph()
        
        for (i, s1) in sentences.enumerated() {
            for s2 in sentences[(i + 1) ..< sentences.count] {
                let similarity = similarity(s1, s2)
                if similarity > 0 {
                    try? graph.addEdge(from: s1, to: s2, withWeight: similarity)
                }
            }
        }
    }
    
    /// Calculate the similarity of two senntences.
    /// - Parameters:
    ///   - a: First sentence.
    ///   - b: Second sentence.
    /// - Returns: Returns a float for how simillar the two sentences are. The larger the greater
    ///   simillarity, the greater the value. Zero is the minimum value.
    func similarity(_ a: Sentence, _ b: Sentence) -> Float {
        if a.words.count == 0 || b.words.count == 0 { return 0.0 }
        let commonWordCount = Float(a.words.intersection(b.words).count)
        let totalWordCount = log10(Float(a.words.count)) + log10(Float(b.words.count))
        return totalWordCount == 0.0 ? 0.0 : commonWordCount / totalWordCount
    }
}

extension TextRank {
    /// Split text into sentences.
    /// - Parameter text: Original text.
    /// - Returns: An array of sentences.
    static func splitIntoSentences(_ text: String, pageID: String = "", additionalStopwords stopwords: [String] = [String]()) -> [Sentence] {
        if text.isEmpty { return [] }

        var x = [Sentence]()
        text.enumerateSubstrings(in: text.range(of: text)!, options: [.bySentences, .localized]) { substring, _, _, _ in
            if let substring = substring, !substring.isEmpty {
                x.append(
                    Sentence(text: substring.trimmingCharacters(in: .whitespacesAndNewlines),
                             originalTextIndex: x.count,
                             pageID: pageID,
                             additionalStopwords: stopwords)
                )
            }
        }
        return Array(Set(x))
    }
}

// Filtering and organizing ranked results.
public extension TextRank {
    /// Filter the results of PageRank by percentile.
    /// - Parameters:
    ///   - results: The results of running PageRank.
    ///   - percentile: The top percentile to filter.
    /// - Returns: A node list of only the top percentile requested.
    func filterTopSentencesFrom(_ results: TextGraph.PageRankResult, top percentile: Float) -> TextGraph.NodeList {
        let idx = Int(Float(results.results.count) * percentile)
        let cutoffScore: Float = results.results.values.sorted()[min(idx, results.results.count - 1)]
        var filteredNodeList: TextGraph.NodeList = [:]
        for (sentence, value) in results.results {
            if value >= cutoffScore {
                filteredNodeList[sentence] = value
            }
        }
        return filteredNodeList
    }
}
