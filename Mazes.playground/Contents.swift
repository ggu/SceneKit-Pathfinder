import PlaygroundSupport
import SceneKit
import GameplayKit

/*
 Welcome to Mazes! Click on the scene to visualize the path or see a new maze.
 */

/// Holds information about the maze.
var maze = Maze()
var sceneView: SCNView?

/// Whether the solution is currently displayed or not.
var hasSolutionDisplayed = false

var nodes = [[SCNNode?]]()

/// Creates a new maze, or solves the newly created maze.
func createOrSolveMaze() {
    if hasSolutionDisplayed {
        createMaze()
    }
    else {
        solveMaze()
    }
}

/**
 Creates a maze object, and creates a visual representation of that maze
 using sprites.
 */
func createMaze() {
    maze = Maze()
    generateMazeNodes()
    hasSolutionDisplayed = false
}

/**
 Uses GameplayKit's pathfinding to find a solution to the maze, then
 solves it.
 */
func solveMaze() {
    guard let solution = maze.solutionPath else {
        assertionFailure("Solution not retrievable from maze.")
        return
    }

    animateSolution(solution)
    hasSolutionDisplayed = true
}

/// Generates sprite nodes that comprise the maze's visual representation.
func generateMazeNodes() {
    // Initialize the an array of sprites for the maze.
    nodes += [[SCNNode?]](repeating: [SCNNode?](repeating: nil, count: (Maze.dimensions * 2) - 1), count: Maze.dimensions
    )

    /*
     Grab the maze's parent node from the scene and use it to
     calculate the size of the maze's cell sprites.
     */
    let mazeParentNode = sceneView?.scene?.rootNode.childNode(withName: "maze", recursively: true)
    let cellDimension: CGFloat = 1

    // Remove existing maze cell sprites from the previous maze.
    mazeParentNode?.enumerateChildNodes({ (node, ptr) in
        let box = SCNBox(width: cellDimension, height: cellDimension, length: cellDimension, chamferRadius: 0.05)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: box, options: nil))
        node.physicsBody?.isAffectedByGravity = true
        let fade = SCNAction.fadeOut(duration: 2.0)
        let remove = SCNAction.removeFromParentNode()
        node.runAction(SCNAction.sequence([fade, remove]))
    })

    let date = Date().addingTimeInterval(0.5)
    let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
        let graphNodes = maze.graph.nodes as? [GKGridGraphNode]
        for node in graphNodes! {
            // Get the position of the maze node.
            let x = Int(node.gridPosition.x)
            let y = Int(node.gridPosition.y)

            /*
             Create a maze sprite node and place the sprite at the correct
             location relative to the maze's parent node.
             */
            let box = SCNBox(width: cellDimension, height: cellDimension, length: cellDimension, chamferRadius: 0.05)
            let material = SCNMaterial()
            material.emission.contents = NSColor.gray
            box.firstMaterial = material
            let mazeNode = SCNNode(geometry: box)

            mazeNode.position = SCNVector3(x: CGFloat(CGFloat(x) * cellDimension), y: 0, z: CGFloat(CGFloat(y) * cellDimension))

            // Add the maze sprite node to the maze's parent node.
            mazeParentNode?.addChildNode(mazeNode)

            /*
             Add the maze sprite node to the 2D array of sprite nodes so we
             can reference it later.
             */
            nodes[x][y] = mazeNode
        }

        // Grab the coordinates of the start and end maze sprite nodes.
        let startNodeX = Int(maze.startNode.gridPosition.x)
        let startNodeY = Int(maze.startNode.gridPosition.y)
        let endNodeX   = Int(maze.endNode.gridPosition.x)
        let endNodeY   = Int(maze.endNode.gridPosition.y)

        // Color the start and end nodes green and red, respectively.
        nodes[startNodeX][startNodeY]?.geometry?.firstMaterial?.emission.contents = NSColor.green
        nodes[startNodeX][startNodeY]?.position
        nodes[endNodeX][endNodeY]?.geometry?.firstMaterial?.emission.contents = NSColor.red
    }

    RunLoop.main.add(timer, forMode: .default)
}

/// Animates a solution to the maze.
func animateSolution(_ solution: [GKGridGraphNode]) {
    /*
     The animation works by animating sprites with different start delays.
     actionDelay represents this delay, which increases by
     an interval of actionInterval with each iteration of the loop.
     */
    var actionDelay: TimeInterval = 0
    let actionInterval = 0.01

    /*
     Light up each sprite in the solution sequence, except for the
     start and end nodes.
     */
    for i in 1...(solution.count - 2) {
        // Grab the position of the maze graph node.
        let x = Int(solution[i].gridPosition.x)
        let y = Int(solution[i].gridPosition.y)

        actionDelay += actionInterval

        if let mazeNode = nodes[x][y] {
            let material = mazeNode.geometry!.firstMaterial!
            let action = SCNAction.sequence([SCNAction.wait(duration: actionDelay), SCNAction.run({ _ in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2

                SCNTransaction.completionBlock = {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.3

                    material.emission.contents = NSColor.magenta

                    SCNTransaction.commit()
                }

                material.emission.contents = NSColor.gray

                SCNTransaction.commit()
            })])
            mazeNode.runAction(action)
        }
    }
}

class ClickContainer {
    @objc
    static func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        createOrSolveMaze()
    }
}

// Load the SCNScene from 'GameScene.scn'
sceneView = SCNView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))

if let scene = SCNScene(named: "GameScene.scn") {

    // Present the scene
    sceneView?.scene = scene
    sceneView?.allowsCameraControl = true

    let clickGesture = NSClickGestureRecognizer(target: ClickContainer.self, action: #selector(ClickContainer.handleClick(_:)))
    var gestureRecognizers = sceneView?.gestureRecognizers
    gestureRecognizers?.append(clickGesture)
    sceneView?.gestureRecognizers = gestureRecognizers!
}

createMaze()

PlaygroundPage.current.needsIndefiniteExecution = true

PlaygroundPage.current.liveView = sceneView
