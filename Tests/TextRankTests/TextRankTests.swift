@testable import TextRank
import XCTest

class TextRankTests: XCTestCase {
    func testInitialization() {
        let textRank = TextRank(text: "Here is some text. There are two sentences.")
        XCTAssertEqual(textRank.sentences.count, 2)
    }

    func testComparingSentences() {
        let textRank = TextRank(text: "")

        var s1 = Sentence(text: "dog bear sheep lion", originalTextIndex: 0)
        var s2 = Sentence(text: "dog bear sheep lion", originalTextIndex: 1)
        var sim = textRank.similarity(s1, s2)
        XCTAssertEqual(sim, 4.0 / (log10(4.0) + log10(4.0)))

        s1 = Sentence(text: "dog bear sheep lion", originalTextIndex: 0)
        s2 = Sentence(text: "dog bear sheep", originalTextIndex: 1)
        sim = textRank.similarity(s1, s2)
        XCTAssertEqual(sim, 3.0 / (log10(4.0) + log10(3.0)))

        s1 = Sentence(text: "dog bear sheep lion to there", originalTextIndex: 0)
        s2 = Sentence(text: "dog bear sheep we them", originalTextIndex: 1)
        sim = textRank.similarity(s1, s2)
        XCTAssertEqual(sim, 3.0 / (log10(4.0) + log10(3.0)))

        s1 = Sentence(text: "", originalTextIndex: 0)
        s2 = Sentence(text: "dog bear sheep we them", originalTextIndex: 1)
        sim = textRank.similarity(s1, s2)
        XCTAssertEqual(sim, 0.0)

        s1 = Sentence(text: "there will", originalTextIndex: 0)
        s2 = Sentence(text: "dog bear sheep we them", originalTextIndex: 1)
        sim = textRank.similarity(s1, s2)
        XCTAssertEqual(sim, 0.0)

        s1 = Sentence(text: "fox peacock there will", originalTextIndex: 0)
        s2 = Sentence(text: "dog bear sheep we them", originalTextIndex: 1)
        sim = textRank.similarity(s1, s2)
        XCTAssertEqual(sim, 0.0)
    }

    func testCreatingSentencesFromChunks() {
        let testChunks = [
            [
                "Unveilin"
            ],
            [
                "Table of content\nTable of content 2 Introduction 3 The Historical Importance of \"Romeo and Juliet\" 3 The Year and Time of Creation 3 The Author: William Shakespeare 3 Part One: Exploring \"Romeo and Juliet\" 4 Chapter 1: The Feuding Families of Verona 4 Chapter 2: Love Blossoms Amidst Conflict 4 Chapter 3: A Secret Union of Hearts 5 Chapter 4: A Duel\'s Dark Consequences 5 Chapter 5: Love Tested by Separation 6 Chapter 6: A Friar\'s Bold Plan Unfolds 6 Chapter 7: Missteps and Fateful Discoveries 7 ", 
                "Chapter 8: A Sleep of Death 7 Chapter 9: The Tragic Farewell 8 Overview 8 Possible Exam Questions and Answers 10\n2"
            ],
            [
                "Introduction\nWelcome to the world of \"Romeo and Juliet,\" a literary gem that has captivated hearts for centuries. In this study guide, we\'ll journey through the pages of this remarkable work by William Shakespeare, exploring its historical importance, the year and time of its creation, and why it continues to be celebrated as one of the greatest literary achievements of all time.\n", 
                "The Historical Importance of \"Romeo and Juliet\"\n\"Romeo and Juliet\" is not just a play; it\'s a cultural touchstone that has left an indelible mark on literature, theater, and society. Written during the Renaissance period in England, between 1594 and 1596, this tragic love story emerged during a time of immense creativity and innovation. It was a time when art, science, and exploration flourished, and Shakespeare\'s works played a pivotal role in shaping the literary landscape of the era.\n", 
                "The Year and Time of Creation\nImagine the cobblestone streets of Elizabethan England, a bustling setting where the ink flowed freely from quills onto parchment. It was during this vibrant period that Shakespeare penned \"Romeo and Juliet.\" While the exact year of its composition remains debated, it is widely believed to have been written around 1595. The play\'s timeless themes of love, conflict, and fate resonated then, just as they continue to resonate today.\n",
                "The Author: William Shakespeare\nAt the heart of this enduring masterpiece stands the genius of William Shakespeare, a playwright and poet whose literary contributions have left an indelible impact on human culture. Born in 1564, Shakespeare crafted stories that transcend time and language barriers. ",
                "His ability to delve into the complexities of human nature, his skill in capturing the range of human emotions, and his knack for weaving captivating narratives have solidified his place as one of history\'s greatest storytellers.\n",
                "\"Romeo and Juliet\" stands as a testament to Shakespeare\'s unparalleled craftsmanship. As we embark on this journey through the play\'s pages, let us marvel at its historical significance, appreciate the genius of its creator, and discover why this timeless tale of love and tragedy continues to resonate with readers and audiences across the world.\n3"
            ]
        ]
        let textRank = TextRank(chunks: testChunks)
        print(textRank)
        XCTAssertEqual(textRank.sentences[0].text, testChunks[0][0].trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertEqual(textRank.sentences[0].pageIndex, 0)
        XCTAssertEqual(textRank.sentences[0].originalTextIndex, 0)

        XCTAssertEqual(textRank.sentences[1].text, testChunks[1][0].trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertEqual(textRank.sentences[1].pageIndex, 1)
        XCTAssertEqual(textRank.sentences[1].originalTextIndex, 0)

        XCTAssertEqual(textRank.sentences[2].text, testChunks[1][1].trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertEqual(textRank.sentences[2].pageIndex, 1)
        XCTAssertEqual(textRank.sentences[2].originalTextIndex, 1)

        XCTAssertEqual(textRank.sentences[8].text, testChunks[2][5].trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertEqual(textRank.sentences[8].pageIndex, 2)
        XCTAssertEqual(textRank.sentences[8].originalTextIndex, 5)
    }

    func testBuildingGraph() {
        var text = "Dog cat bird. Sheep dog cat. Horse cow fish."
        let textRank = TextRank(text: text)
        textRank.buildGraph()
        XCTAssertEqual(textRank.graph.nodes.count, 2)
        XCTAssertEqual(textRank.graph.edges.count, 2)

        text = "Dog cat bird. Sheep dog cat peacock. Horse cow fish dog chicken."
        textRank.pages = [text]
        textRank.buildGraph()
        XCTAssertEqual(textRank.graph.nodes.count, 3)
        XCTAssertEqual(textRank.graph.edges.count, 3)
        let nodes = textRank.graph.nodes.keys.sorted(by: { $0.length < $1.length })
        XCTAssertGreaterThan(
            textRank.graph.getEdgeWeight(from: nodes[0], to: nodes[1]),
            textRank.graph.getEdgeWeight(from: nodes[0], to: nodes[2])
        )
    }

    func testSimplePageRank() throws {
        let text = "Dog cat bird. Sheep dog cat. Horse cow fish. Horse cat lizard. Lizard dragon bird."
        let textRank = TextRank(text: text)
        let pageRankResults = try textRank.runPageRank()
        XCTAssertTrue(pageRankResults.didConverge)
        XCTAssertLessThan(pageRankResults.iterations, 20)
        XCTAssertEqual(pageRankResults.results.count, 5)
        print(pageRankResults.results)
        XCTAssertEqual(
            pageRankResults.results[Sentence(text: "Horse cat lizard.", originalTextIndex: 3)],
            pageRankResults.results.values.max()
        )
    }

    func testFilteringTopSentences() throws {
        // Given
        let text = "Dog cat bird. Sheep dog cat. Horse cow fish. Horse cat lizard. Lizard dragon bird."
        let textRank = TextRank(text: text)
        let results = try textRank.runPageRank()

        // When
        let filteredResults = textRank.filterTopSentencesFrom(results, top: 0.75)

        // Then
        XCTAssertTrue(filteredResults.count < results.results.count)
        XCTAssertTrue(filteredResults.count == 2)
    }

    func testStopwordsAreRemoved() {
        // Given
        let text = "Here are some sentences dog cat. With intentional stopwords gator. And some words that are not."

        // When
        let textRank = TextRank(text: text)

        // Then
        XCTAssertEqual(textRank.sentences.count, 2)
        XCTAssertEqual(textRank.sentences[0].length, 3)
        XCTAssertEqual(textRank.sentences.filter { $0.originalTextIndex == 0 }[0].words,
                       Set(["sentences", "dog", "cat"]))
        XCTAssertEqual(textRank.sentences.filter { $0.originalTextIndex == 1 }[0].words,
                       Set(["intentional", "stopwords", "gator"]))
        XCTAssertEqual(textRank.sentences[1].length, 3)
    }

    func testAdditionalStopwords() {
        // Given
        let text = "Here are some sentences dog cat. With intentional stopwords gator. And some words that are not."
        let additionalStopwords = ["dog", "gator"]

        // When
        let textRank = TextRank(text: text)
        textRank.stopwords = additionalStopwords

        // Then
        XCTAssertEqual(textRank.sentences.count, 2)
        XCTAssertEqual(textRank.sentences[0].length, 2)
        XCTAssertEqual(textRank.sentences.filter { $0.originalTextIndex == 0 }[0].words,
                       Set(["sentences", "cat"]))
        XCTAssertEqual(textRank.sentences.filter { $0.originalTextIndex == 1 }[0].words,
                       Set(["intentional", "stopwords"]))
        XCTAssertEqual(textRank.sentences[1].length, 2)
    }
}
