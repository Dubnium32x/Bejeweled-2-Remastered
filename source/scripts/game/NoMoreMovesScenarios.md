# No More Moves Scenaios

### In Bejeweled 2...
There are a few different things that can happen when the system sees no more valid moves in the board.

### In Classic, Twilight, Finity, and Original...
If the system sees no more valid moves, the game will end. 
#### Effect
- Announcer will go "No More Moves..."
- Announcer text for this message appears on screen just like "GO!" does.
- During this, the gems will stop responding to input and play a shaking animation.
- After this, the gems will shoot out from the board.
    - They can rotate, go in any depth (scale), and shoot from any velocity.

### In Action, Hyper and Endless...
If the system sees no more valid moves, it will just reshuffle the board.
#### Effect
- Announcer will go "No More Moves..."
- Announcer text for this message appears on screen just like "GO!" does.
- During this the gems will stop responding to input and start reshuffling.
- Do we wanna do like a spiral effect for the reshuffle animation like in Bejeweled 1?
- Once the gems are in place, there will be a brief pause before the player can make a move. Add a sfx and a shine to indicate that the board is clean.

### In Puzzle and Cognito...
If the system sees no more valid moves, it'll prompt the user to reset the board or undo.
#### Effect
- No effect on the gems.
- A dialog will appear asking the user to reset the board or undo.
- If the user chooses to reset, the board will go back to the initial puzzle formation.
- If the user chooses to undo, the last move will be undone and the board will return to the state before the last move.