<h1 align="center">Data-Driven First Person Controller</h1>

<h2 align="left">Overview</h2>

This project consists of a basic, resource-driven implementation of a first-person player controller, and an environmental scene used to test the former's functionality. This project is designed for Godot Engine versions 4.4.1 or above. The main scene of the project is set to the aforementioned environmental scene.

The first-person player controller comes with the following features:

- State machine-driven movement. Additional movement states can be added by creating resource-scripts inheriting from the FPMoveState class. Comes with the following states pre-built: OnGround, InAir, and Frozen. 
  
- A smooth first-person camera. The camera node is designed to smoothly (and quickly) move towards a target position, which is by default where the player's "head" should be.

This player controller is built with behavior-altering, resource-based components in mind. This allows for scalable customization of player movement behavior. The following components are included:

  - A camera movement effect component. Creates a Vector3 containing calculated values for head-bobbing, fall-kicking, and movement-based camera tilting effects - the intensity of which can be modified. This vector is then passed to the parent camera via signal, which is then saved as a modifier applied to the camera target's position and the camera's rotation.
 
  - A camera lean component. Allows the player to move the camera lerp target along its x-axis. Combined with a directional camera-rotation effect, this allows the player to peak around corners. These changes are sent to the parent camera as modifiers to the target's position and the camera's rotation.

- A crouch component. This allows the player to enter various "stance states", which dynamically alter their collision shape and the position of the camera's lerp target. The component sends its data to the player's main movement script via signal, which then modifies the player's collision dimensions and movement speed as requested.

- A sprint component. This allows the player to move at a faster speed. This effect is cancelled out by the crouch component whenever the player is considered to be crouching.

If any of the default player controller components don't suit a project, they can be removed with no resulting functionality issues. The component system designed for this project is made with easy integration and removal of components in mind. If any components do need to communicate with each other, it is done through the use of signals to enforce clean design structure.

<h2 align="left">Controls</h2>

The following actions are executed with the following controls:
- Horizontal movement: W, A, S, D
- Camera movement: Mouse
- Jumping: Space
- Crouching: C
- Leaning: Q, E
- Free Mouse: Escape

The control scheme (save for the camera's mouse-driven movement and the escape key) can be modified in the Godot Editor in: Project Settings &rarr; Input Map
