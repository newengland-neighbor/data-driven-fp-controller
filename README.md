<h1 align="center">Data-Driven First Person Controller</h1>

<h2 align="left">Overview</h2>

This project consists of a basic, resource-driven implementation of a first-person player controller, and an environmental scene used to test the former's functionality. The main scene of the project is set to the aforementioned environmental scene.

The first-person player controller comes with the following features:

- A state machine-driven movement component. Additional movement states can be added by creating resource-scripts inheriting from the FPMoveState class. Comes with the following states pre-built: idle, moving, jumping, falling.
  
- A first-person camera component. Spawns a Camera3D node, and a target node which the camera linearly interpolates its position to match. Both are set to be children of the player node, though the camera node itself is decoupled from the player's position. This is done to allow for smooth, yet responsive, camera movement. This component's behavior can be further modified through the use of subcomponents inheriting from the Subcomponent resource class. The camera component comes with the following subcomponents:

  - A camera movement effect component. Creates a Vector3 containing calculated values for head-bobbing, fall-kicking, and movement-based camera tilting effects - the intensity of which can be modified.
 
  - A camera lean component. Allows the player to move the camera lerp target along its x-axis. Combined with a directional camera-rotation effect, this allows the player to peak around corners.

- A crouch component. This allows the player to enter various "stance states", which dynamically alter their collision shape and the position of the camera's lerp target.

If any of the default player controller components don't suit a project, they can be removed with no resulting functionality issues. The component system designed for this project is made with easy integration and removal of components in mind. If any components do need to communicate with each other, it is done through the use of signals to enforce clean design structure.

<h2 align="left">Controls</h2>

The following actions are executed with the following controls:
- Horizontal movement: W, A, S, D
- Camera movement: Mouse
- Jumping: Space
- Crouching: C

The control scheme can be modified in-editor in: Project Settings -> Input Map
