import Foundation

class Game2048Model: ObservableObject {
    @Published var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @Published var score: Int = 0
    @Published var gameOver: Bool = false
    @Published var gameWon: Bool = false
    var moves: Int = 0
    var gameHistory = GameHistory()
    
    init() {
        addNewTile()
        addNewTile()
    }
    
    func addNewTile() {
        let emptyCells = getEmptyCells()
        if !emptyCells.isEmpty {
            let randomCell = emptyCells.randomElement()!
            board[randomCell.row][randomCell.col] = Int.random(in: 1...2) * 2
        }
    }
    
    private func getEmptyCells() -> [(row: Int, col: Int)] {
        var emptyCells: [(row: Int, col: Int)] = []
        for row in 0..<4 {
            for col in 0..<4 {
                if board[row][col] == 0 {
                    emptyCells.append((row, col))
                }
            }
        }
        return emptyCells
    }
    
    func move(direction: MoveDirection) {
        var moved = false
        
        switch direction {
        case .up:
            moved = moveUp()
        case .down:
            moved = moveDown()
        case .left:
            moved = moveLeft()
        case .right:
            moved = moveRight()
        }
        
        if moved {
            moves += 1
            addNewTile()
            checkGameStatus()
        }
    }
    
    private func moveUp() -> Bool {
        var moved = false
        for col in 0..<4 {
            let oldCol = getColumn(col)
            let (newCol, colMoved, points) = mergeLine(oldCol)
            if colMoved {
                moved = true
                score += points
                setColumn(col, newCol)
            }
        }
        return moved
    }
    
    private func moveDown() -> Bool {
        var moved = false
        for col in 0..<4 {
            let oldCol = getColumn(col).reversed()
            let (newCol, colMoved, points) = mergeLine(Array(oldCol))
            if colMoved {
                moved = true
                score += points
                setColumn(col, newCol.reversed())
            }
        }
        return moved
    }
    
    private func moveLeft() -> Bool {
        var moved = false
        for row in 0..<4 {
            let oldRow = board[row]
            let (newRow, rowMoved, points) = mergeLine(oldRow)
            if rowMoved {
                moved = true
                score += points
                board[row] = newRow
            }
        }
        return moved
    }
    
    private func moveRight() -> Bool {
        var moved = false
        for row in 0..<4 {
            let oldRow = board[row].reversed()
            let (newRow, rowMoved, points) = mergeLine(Array(oldRow))
            if rowMoved {
                moved = true
                score += points
                board[row] = newRow.reversed()
            }
        }
        return moved
    }
    
    private func getColumn(_ col: Int) -> [Int] {
        var column: [Int] = []
        for row in 0..<4 {
            column.append(board[row][col])
        }
        return column
    }
    
    private func setColumn(_ col: Int, _ newCol: [Int]) {
        for row in 0..<4 {
            board[row][col] = newCol[row]
        }
    }
    
    private func mergeLine(_ line: [Int]) -> (mergedLine: [Int], moved: Bool, points: Int) {
        var points = 0
        let filteredLine = line.filter { $0 != 0 }
        var mergedLine: [Int] = []
        var i = 0
        
        while i < filteredLine.count {
            if i + 1 < filteredLine.count && filteredLine[i] == filteredLine[i + 1] {
                let mergedValue = filteredLine[i] * 2
                mergedLine.append(mergedValue)
                points += mergedValue
                i += 2
            } else {
                mergedLine.append(filteredLine[i])
                i += 1
            }
        }
        
        // Pad with zeros to maintain 4 cells
        while mergedLine.count < 4 {
            mergedLine.append(0)
        }
        
        // Check if the line moved
        var moved = false
        if mergedLine != line {
            moved = true
        }
        
        return (mergedLine, moved, points)
    }
    
    private func checkGameStatus() {
        // Check for win
        var highestTile = 0
        for row in 0..<4 {
            for col in 0..<4 {
                if board[row][col] > highestTile {
                    highestTile = board[row][col]
                }
                if board[row][col] == 2048 {
                    gameWon = true
                }
            }
        }
        
        // Check for game over
        if getEmptyCells().isEmpty && !canMove() {
            gameOver = true
            // Save game record when game is over
            saveGameRecord(highestTile: highestTile)
        }
    }
    
    private func canMove() -> Bool {
        // Check horizontal moves
        for row in 0..<4 {
            for col in 0..<3 {
                if board[row][col] == board[row][col + 1] {
                    return true
                }
            }
        }
        
        // Check vertical moves
        for row in 0..<3 {
            for col in 0..<4 {
                if board[row][col] == board[row + 1][col] {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func saveGameRecord(highestTile: Int) {
        gameHistory.addRecord(score: score, highestTile: highestTile, moves: moves)
    }
    
    func reset() {
        board = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0
        gameOver = false
        gameWon = false
        moves = 0
        addNewTile()
        addNewTile()
    }
}

enum MoveDirection {
    case up, down, left, right
}
