import SwiftUI

struct Player: Identifiable {
    var id: Int
    var name: String
}

struct ContentView: View {
    @State private var isGameActive: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // Homepage
                VStack(spacing: 10) {
                    Text("Snooker Marker")
                        .font(Font.largeTitle.bold())
                        .foregroundStyle(.primary)
                    Text("Click Start for a New Round!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                }
                Spacer()
                
                // Start button
                Button(action: {
                    startGame()
                }) {
                    Text("Start Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(isPresented: $isGameActive) {
                GameView()
            }
        }
    }
    private func startGame() {
        isGameActive = true
    }
}

enum HistoryType {
    case shot(points: Int)
    case clear(p1Prev: Int, p2Prev: Int)
    case foul(points: Int, recveiver: Int)
}

struct HistoryEntry {
    let playerNumber: Int
    let type: HistoryType
}

struct GameView: View {
    @State private var player1Name: String = "Player 1"
    @State private var player2Name: String = "Player 2"
    @State private var player1Score: Int = 0
    @State private var player2Score: Int = 0
    @State private var activePlayer: Int = 1
    @State private var scoreHistory: [HistoryEntry] = []
    @State private var showOverflowAlert: Bool = false
    @State private var showFoulMenu = false
    let balls = ["RedBall", "YellowBall", "GreenBall", "BrownBall", "BlueBall", "PinkBall", "BlackBall"]
    let foulPoints = [4, 5, 6, 7]
    var body: some View {
        VStack {
            Text("Game View")
                .font(.title)
                .padding()
            Spacer()
            
            // Player Scoring and Active Status Panel
            HStack(spacing: 20) {
                // Player 1 Box
                VStack(spacing: 12) {
                    TextField("Player 1", text: $player1Name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("\(player1Score)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    
                    Button(action: {activePlayer = 1}) {
                        Text("Hitting")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                            .background(activePlayer == 1 ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                    }
                }
                .padding()
                .background(activePlayer == 1 ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(activePlayer == 1 ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
                )
                
                Divider().frame(height: 100)
                
                // Player 2 Box
                VStack(spacing: 12) {
                    TextField("Player 2", text: $player2Name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("\(player2Score)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    
                    Button(action: {activePlayer = 2}) {
                        Text("Hitting")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                            .background(activePlayer == 2 ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                    }
                }
                .padding()
                .background(activePlayer == 2 ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(activePlayer == 2 ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
                )
            }
            .padding(.horizontal)
            Spacer()
            
            // Balls
            HStack(spacing: 8) {
                ForEach(balls, id: \.self) { ballAsset in
                    Button {
                        ballTapped(name: ballAsset)
                    } label: {
                        Image(ballAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            Spacer()
            .navigationTitle("Match Setup")
            .navigationBarTitleDisplayMode(.inline)
            
            // Foul
            Button(action: {
                showFoulMenu = true
            }) {
                Label("Foul", systemImage: "exclamationmark.triangle")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .confirmationDialog("Select Foul Points", isPresented: $showFoulMenu, titleVisibility: .visible) {
                ForEach(foulPoints, id: \.self) { points in
                    Button("+\(points)") {
                        foulScores(points: points)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            Spacer()
            
            // Clear Scores
            Button(action: clearScores) {
                Label("Clear Scores", systemImage: "trash")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Undo Action
            Button(action: undoLastStep) {
                Label("Undo Last Step", systemImage: "arrow.uturn.backward")
                .font(.subheadline.bold())
                .foregroundColor(scoreHistory.isEmpty ? .gray : .red)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(scoreHistory.isEmpty ? Color.gray.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(scoreHistory.isEmpty) // Disable button if there's no history to undo
            .padding(.top, 16)
            Spacer()
        }
        .alert("WARNING", isPresented: $showOverflowAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Score Exceed Limits!")
        }
    }
    
    private func ballTapped(name: String) {
        print("\(name) was pressed")
        let points: Int
        switch name {
            case "RedBall": points = 1
            case "YellowBall": points = 2
            case "GreenBall": points = 3
            case "BrownBall": points = 4
            case "BlueBall": points = 5
            case "PinkBall": points = 6
            case "BlackBall": points = 7
            default: points = 0
        }
        guard points > 0 else { return }
        let entry = HistoryEntry(playerNumber: activePlayer, type: .shot(points: points))
        scoreHistory.append(entry)
        
        if (activePlayer == 1) {
            if (checkOverFlow(points: player1Score + points)) {
                player1Score += points
            }
        }
        else {
            if (checkOverFlow(points: player2Score + points)) {
                player2Score += points
            }
        }
    }
    
    private func checkOverFlow(points: Int) -> Bool {
        if (points > 300) {
            showOverflowAlert = true
            return false
        }
        return true
    }
    
    private func foulScores(points: Int) {
        let receiver = (activePlayer == 1) ? 2 : 1
        let currOpponentScore = (receiver == 2) ? player2Score : player1Score
        if (!checkOverFlow(points: currOpponentScore + points)) { return }
        
        let entry = HistoryEntry(playerNumber: activePlayer, type: .foul(points: points, recveiver: receiver))
        scoreHistory.append(entry)
        if (receiver == 1) {
            player1Score += points
        }
        else {
            player2Score += points
        }
    }
    
    private func clearScores() {
        if (player1Score == 0 && player2Score == 0) { return }
        let entry = HistoryEntry(playerNumber: 0, type: .clear(p1Prev: player1Score, p2Prev: player2Score))
        scoreHistory.append(entry)
        player1Score = 0
        player2Score = 0
    }
    
    private func undoLastStep() {
        guard let lastEntry = scoreHistory.popLast() else { return }
        switch lastEntry.type {
        case .shot(let points):
            if lastEntry.playerNumber == 1 {
                player1Score = max(0, player1Score - points)
            }
            else {
                player2Score = max(0, player2Score - points)
            }
            
        case .clear(let p1Prev, let p2Prev):
            player1Score = p1Prev
            player2Score = p2Prev
            
        case .foul(let points, let receiver):
            if receiver == 1 {
                player1Score = max(0, player1Score - points)
            }
            else {
                player2Score = max(0, player2Score - points)
            }
        }
    }
}

#Preview {
    ContentView()
}
