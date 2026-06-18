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

enum NextRequiredBall: Equatable {
    case red
    case anyColor
    case strictColor(Int)
}

enum HistoryType {
    case shot(points: Int, prevState: NextRequiredBall, prevSafe: Bool)
    case clear(p1Prev: Int, p2Prev: Int, redBallsPrev: Int, remainingPrev: Int, nextReqPrev: NextRequiredBall, prevSafe: Bool)
    case foul(points: Int, receiver: Int)
    case freeBall(color: String, prevState: NextRequiredBall, prevSafe: Bool)
    case miss(prevState: NextRequiredBall, prevSafe: Bool, prevPlayer: Int)
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
    @State private var nextRequired: NextRequiredBall = .red
    @State private var isLastColorAfterRedSafe: Bool = false
    let balls = ["RedBall", "YellowBall", "GreenBall", "BrownBall", "BlueBall", "PinkBall", "BlackBall"]
    
    @State private var showFoulMenu = false
    let foulPoints = [4, 5, 6, 7]
    
    @State private var showFreeBallMenu = false
    let freeBallColors = ["YellowBall", "GreenBall", "BrownBall", "BlueBall", "PinkBall", "BlackBall"]

    @State private var remaining: Int = 147
    @State private var remainingRedBalls: Int = 15

    private var player1Behind: Int {
        max(0, player2Score - player1Score)
    }
    
    private var player2Behind: Int {
        max(0, player1Score - player2Score)
    }
    
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Behind: \(player1Behind)")
                            .foregroundColor(player1Behind > remaining ? .red : .secondary)
                        Text("Remaining: \(remaining)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption.bold())
                    .padding(.top, 4)
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Behind: \(player2Behind)")
                            .foregroundColor(player2Behind > remaining ? .red : .secondary)
                        Text("Remaining: \(remaining)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption.bold())
                    .padding(.top, 4)
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
            
            // Show remaining red balls
            Text("Red Balls Left: \(remainingRedBalls)")
                .font(.footnote.bold())
                .foregroundColor(.red)
                .padding(.top, 8)
            
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
                // Miss
                Button {
                    missTapped()
                } label: {
                    Text("Miss")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 44, height: 32)
                        .background(Color.gray)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            Spacer()
            .navigationTitle("Match Setup")
            .navigationBarTitleDisplayMode(.inline)
            
            HStack(alignment: .center, spacing: 30) {
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
                
                // Free Ball
                Button(action: {
                    showFreeBallMenu = true
                }) {
                    Label("Free Ball", systemImage: "star.circle")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .confirmationDialog("Choose the Colour Ball", isPresented: $showFreeBallMenu, titleVisibility: .visible) {
                    ForEach(freeBallColors, id: \.self) { ball in
                        let displayName = ball.replacingOccurrences(of: "Ball", with: "")   // increase readability
                        Button(displayName) {
                            freeBallColors(color: ball)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
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
        
        switch nextRequired {
        case .red:
            if (name != "RedBall") { return }
        case .anyColor:
            if (name == "RedBall") { return }
        case .strictColor(let requiredPoints):
            if (points != requiredPoints) { return }
        }
        
        let stateSnapshot = nextRequired
        let safeSnapshot = isLastColorAfterRedSafe
        
        if (name == "RedBall") {
            if (remainingRedBalls > 0) {
                remainingRedBalls -= 1
                remaining -= 8
                if (remainingRedBalls == 0) {
                    isLastColorAfterRedSafe = true
                }
                nextRequired = .anyColor
            }
        }
        else {
            if (isLastColorAfterRedSafe) {
                // Potted last red ball
                isLastColorAfterRedSafe = false
                nextRequired = .strictColor(2)
            }
            else if (remainingRedBalls == 0) {
                remaining = max(0, remaining - points)
                if (points < 7) {
                    nextRequired = .strictColor(points + 1)
                }
                else {
                    nextRequired = .strictColor(7)
                }
            }
            else {
                nextRequired = .red
            }
        }
        
        if (activePlayer == 1) {
            if (checkOverFlow(points: player1Score + points)) {
                let entry = HistoryEntry(playerNumber: activePlayer, type: .shot(points: points, prevState: stateSnapshot, prevSafe: safeSnapshot))
                scoreHistory.append(entry)
                player1Score += points
            }
        }
        else {
            if (checkOverFlow(points: player2Score + points)) {
                let entry = HistoryEntry(playerNumber: activePlayer, type: .shot(points: points, prevState: stateSnapshot, prevSafe: safeSnapshot))
                scoreHistory.append(entry)
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
        
        let entry = HistoryEntry(playerNumber: activePlayer, type: .foul(points: points, receiver: receiver))
        scoreHistory.append(entry)
        
        if (receiver == 1) {
            player1Score += points
        }
        else {
            player2Score += points
        }
    }
    
    private func freeBallColors(color: String) {
        let points = 1
        let currScore = (activePlayer == 1) ? player1Score : player2Score
        if (!checkOverFlow(points: currScore + points)) { return }
        
        let entry = HistoryEntry(playerNumber: activePlayer, type: .freeBall(color: color, prevState: nextRequired, prevSafe: isLastColorAfterRedSafe))
        scoreHistory.append(entry)
        
        nextRequired = .anyColor
        
        if (activePlayer == 1) {
            player1Score += points
        }
        else {
            player2Score += points
        }
    }
    
    private func clearScores() {
        if (player1Score == 0 && player2Score == 0 && remainingRedBalls == 15) { return }
        let entry = HistoryEntry(playerNumber: 0, type: .clear(
            p1Prev: player1Score,
            p2Prev: player2Score,
            redBallsPrev: remainingRedBalls,
            remainingPrev: remaining,
            nextReqPrev: nextRequired,
            prevSafe: isLastColorAfterRedSafe))
        scoreHistory.append(entry)
        player1Score = 0
        player2Score = 0
        remainingRedBalls = 15
        remaining = 147
        nextRequired = .red
        isLastColorAfterRedSafe = false
    }
    
    private func undoLastStep() {
        guard let lastEntry = scoreHistory.popLast() else { return }
        
        switch lastEntry.type {
        case .shot(let points, let prevState, let prevSafe):
            if (lastEntry.playerNumber == 1) {
                player1Score = max(0, player1Score - points)
            }
            else {
                player2Score = max(0, player2Score - points)
            }
            
            if (points == 1) {
                remainingRedBalls = min(15, remainingRedBalls + 1)
                remaining += 8
            }
            else if (remainingRedBalls == 0 && !prevSafe) {
                remaining += points
            }
            nextRequired = prevState
            isLastColorAfterRedSafe = prevSafe
            
        case .clear(let p1Prev, let p2Prev, let redBallsPrev, let remainingPrev, let nextReqPrev, let safePrev):
            player1Score = p1Prev
            player2Score = p2Prev
            remainingRedBalls = redBallsPrev
            remaining = remainingPrev
            nextRequired = nextReqPrev
            isLastColorAfterRedSafe = safePrev
            
        case .foul(let points, let receiver):
            if (receiver == 1) {
                player1Score = max(0, player1Score - points)
            }
            else {
                player2Score = max(0, player2Score - points)
            }
        
        case .freeBall(let color, let prevState, let prevSafe):
            if (lastEntry.playerNumber == 1) {
                player1Score = max(0, player1Score - 1)
            }
            else {
                player2Score = max(0, player2Score - 1)
            }
            nextRequired = prevState
            isLastColorAfterRedSafe = prevSafe
            
        case .miss(let prevState, let prevSafe, let prevPlayer):
            nextRequired = prevState
            isLastColorAfterRedSafe = prevSafe
            activePlayer = prevPlayer
        }
    }
    
    private func missTapped() {
        let nextState: NextRequiredBall
        if (nextRequired == .anyColor) {
            nextState = .red
        }
        else {
            nextState = nextRequired
        }
        
        let entry = HistoryEntry(playerNumber: activePlayer, type: .miss(prevState: nextRequired, prevSafe: isLastColorAfterRedSafe, prevPlayer: activePlayer))
        scoreHistory.append(entry)
        
        nextRequired = nextState
        activePlayer = (activePlayer == 1) ? 2 : 1
    }
}

    

#Preview {
    ContentView()
}
