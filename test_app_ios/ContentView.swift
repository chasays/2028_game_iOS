//
//  ContentView.swift
//  test_app_ios
//
//  Created by Rik Xiao on 2025/9/2.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameModel = Game2048Model()
    @State private var showHistory = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with title and score
            HStack {
                Text("2048")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(gameModel.score)")
                        .font(.title2)
                        .bold()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Game board
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { col in
                            TileView(value: gameModel.board[row][col])
                        }
                    }
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            // Horizontal swipe
                            if value.translation.width > 0 {
                                gameModel.move(direction: .right)
                            } else {
                                gameModel.move(direction: .left)
                            }
                        } else {
                            // Vertical swipe
                            if value.translation.height > 0 {
                                gameModel.move(direction: .down)
                            } else {
                                gameModel.move(direction: .up)
                            }
                        }
                    }
            )
            
            // Control buttons
            HStack {
                Button(action: {
                    gameModel.reset()
                }) {
                    Text("New Game")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    showHistory = true
                }) {
                    Text("History")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Game status indicators
                if gameModel.gameOver {
                    Text("Game Over!")
                        .foregroundColor(.red)
                        .font(.title3)
                        .bold()
                } else if gameModel.gameWon {
                    Text("You Win!")
                        .foregroundColor(.green)
                        .font(.title3)
                        .bold()
                }
            }
            .padding(.horizontal)
            
            // Instructions
            Text("Swipe or use arrow keys to move tiles")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .sheet(isPresented: $showHistory) {
            GameHistoryView(gameHistory: gameModel.gameHistory)
        }
        .onAppear {
            // Add keyboard support for arrow keys
            #if os(macOS)
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NSEvent.keyDown"),
                object: nil,
                queue: .main
            ) { notification in
                // Handle arrow key events
            }
            #endif
        }
    }
}

struct TileView: View {
    let value: Int
    
    var body: some View {
        Text(value == 0 ? "" : "\(value)")
            .font(.title2)
            .bold()
            .frame(width: 70, height: 70)
            .background(tileColor)
            .foregroundColor(tileTextColor)
            .cornerRadius(8)
    }
    
    private var tileColor: Color {
        switch value {
        case 0: return Color.gray.opacity(0.3)
        case 2: return Color(red: 238/255, green: 228/255, blue: 218/255)
        case 4: return Color(red: 237/255, green: 224/255, blue: 200/255)
        case 8: return Color(red: 242/255, green: 177/255, blue: 121/255)
        case 16: return Color(red: 245/255, green: 149/255, blue: 99/255)
        case 32: return Color(red: 246/255, green: 124/255, blue: 95/255)
        case 64: return Color(red: 246/255, green: 94/255, blue: 59/255)
        case 128: return Color(red: 237/255, green: 207/255, blue: 114/255)
        case 256: return Color(red: 237/255, green: 204/255, blue: 97/255)
        case 512: return Color(red: 237/255, green: 200/255, blue: 80/255)
        case 1024: return Color(red: 237/255, green: 197/255, blue: 63/255)
        case 2048: return Color(red: 237/255, green: 194/255, blue: 46/255)
        default: return Color(red: 60/255, green: 58/255, blue: 50/255)
        }
    }
    
    private var tileTextColor: Color {
        if value == 0 || value == 2 || value == 4 {
            return .black
        } else {
            return .white
        }
    }
}

#Preview {
    ContentView()
}