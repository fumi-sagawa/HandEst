#!/usr/bin/env swift

import Foundation

// 純粋関数・Reducerのテストカバレッジチェックスクリプト
// 
// 使用方法: ./Scripts/check-test-coverage.swift
//
// このスクリプトは以下をチェックします:
// 1. Reducer の reduce メソッドに対応するテストの存在
// 2. public/internal な純粋関数に対応するテストの存在
// 3. Feature ファイルに対応する Test ファイルの存在

struct TestCoverageChecker {
    let projectPath: String
    var missingTests: [String] = []
    
    init() {
        self.projectPath = FileManager.default.currentDirectoryPath
    }
    
    // Featureファイルを検索
    func findFeatureFiles() -> [String] {
        let fileManager = FileManager.default
        var featureFiles: [String] = []
        
        let featuresPath = "\(projectPath)/HandEst/Features"
        
        if let enumerator = fileManager.enumerator(atPath: featuresPath) {
            for case let file as String in enumerator {
                if file.hasSuffix("Feature.swift") && !file.contains("Tests") {
                    featureFiles.append("\(featuresPath)/\(file)")
                }
            }
        }
        
        return featureFiles
    }
    
    // 対応するテストファイルの存在をチェック
    func checkTestFileExists(for featureFile: String) -> Bool {
        let testFileName = featureFile
            .replacingOccurrences(of: "/Features/", with: "Tests/")
            .replacingOccurrences(of: ".swift", with: "Tests.swift")
        
        return FileManager.default.fileExists(atPath: testFileName)
    }
    
    // ファイル内の純粋関数を検出（簡易版）
    func findPureFunctions(in file: String) -> [String] {
        guard let content = try? String(contentsOfFile: file) else { return [] }
        
        var functions: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // Reducerのreduceメソッド
            if line.contains("func reduce(") && line.contains("into state:") {
                functions.append("reduce")
            }
            
            // public/internal関数（簡易的な検出）
            if (line.contains("public func") || line.contains("internal func") || line.trimmingCharacters(in: .whitespaces).hasPrefix("func")) 
                && !line.contains("async")
                && !line.contains("Task")
                && !line.contains("Effect")
                && !line.contains("private") {
                
                // 関数名を抽出
                if let funcName = extractFunctionName(from: line) {
                    functions.append(funcName)
                }
            }
        }
        
        return functions
    }
    
    // 関数名を抽出
    func extractFunctionName(from line: String) -> String? {
        let pattern = "func\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\("
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex?.firstMatch(in: line, range: range),
           let nameRange = Range(match.range(at: 1), in: line) {
            return String(line[nameRange])
        }
        
        return nil
    }
    
    // テストファイル内でテストされている関数をチェック
    func findTestedFunctions(in testFile: String) -> Set<String> {
        guard let content = try? String(contentsOfFile: testFile) else { return [] }
        
        var testedFunctions = Set<String>()
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // テスト関数名から推測
            if line.contains("func test") {
                let lowercased = line.lowercased()
                
                // reduce のテスト
                if lowercased.contains("reduce") {
                    testedFunctions.insert("reduce")
                }
                
                // その他の関数名を検出
                if let funcName = extractTestTargetFunction(from: line) {
                    testedFunctions.insert(funcName)
                }
            }
            
            // store.send() の呼び出しをチェック（Reducerテスト）
            if line.contains("store.send(") {
                testedFunctions.insert("reduce")
            }
        }
        
        return testedFunctions
    }
    
    // テスト関数名からテスト対象を推測
    func extractTestTargetFunction(from testLine: String) -> String? {
        // testCalculateFocalLength -> calculateFocalLength
        let pattern = "func test([A-Z][a-zA-Z0-9]*)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: testLine.utf16.count)
        
        if let match = regex?.firstMatch(in: testLine, range: range),
           let nameRange = Range(match.range(at: 1), in: testLine) {
            let name = String(testLine[nameRange])
            // 最初の文字を小文字に
            return name.prefix(1).lowercased() + name.dropFirst()
        }
        
        return nil
    }
    
    // メインのチェック処理
    mutating func check() -> Bool {
        let featureFiles = findFeatureFiles()
        
        print("🔍 テストカバレッジをチェック中...")
        print("   対象: \(featureFiles.count) 個のFeatureファイル\n")
        
        for featureFile in featureFiles {
            let fileName = URL(fileURLWithPath: featureFile).lastPathComponent
            print("📄 \(fileName)")
            
            // テストファイルの存在チェック
            let testFile = featureFile
                .replacingOccurrences(of: "/HandEst/Features/", with: "/HandEstTests/")
                .replacingOccurrences(of: ".swift", with: "Tests.swift")
            
            if !FileManager.default.fileExists(atPath: testFile) {
                print("   ❌ テストファイルが見つかりません")
                missingTests.append("\(fileName) のテストファイル")
                continue
            }
            
            // 純粋関数の検出
            let pureFunctions = findPureFunctions(in: featureFile)
            let testedFunctions = findTestedFunctions(in: testFile)
            
            // カバレッジチェック
            for function in pureFunctions {
                if testedFunctions.contains(function) {
                    print("   ✅ \(function)")
                } else {
                    print("   ❌ \(function) のテストがありません")
                    missingTests.append("\(fileName) の \(function)")
                }
            }
        }
        
        // 結果のサマリー
        print("\n" + String(repeating: "=", count: 50))
        
        if missingTests.isEmpty {
            print("✅ すべての純粋関数とReducerにテストが存在します！")
            return true
        } else {
            print("❌ 以下のテストが不足しています:")
            for missing in missingTests {
                print("   - \(missing)")
            }
            print("\nテストを追加してください。")
            return false
        }
    }
}

// メイン処理
var checker = TestCoverageChecker()
let success = checker.check()

// pre-commitで使用する場合のexit code
exit(success ? 0 : 1)