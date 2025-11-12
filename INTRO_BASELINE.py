from psychopy import visual, core, event

# --- Window ---
win = visual.Window(fullscr=True, color='black', units='height')  # use 'height' for consistent scaling

# --- Phase 1: Instruction screen (1 minute) ---
instruction_text = """Please sit comfortably, remain still, and breathe normally.
The recording will start shortly."""
instruction = visual.TextStim(win, text=instruction_text, color='white', height=0.03, wrapWidth=1.2)

instruction.draw()
win.flip()

# Allow early exit during this phase
timer = core.Clock()
while timer.getTime() < 60:
    if 'space' in event.getKeys(keyList=['space']):
        win.close()
        core.quit()

# --- Phase 2: Neutral baseline (2 minutes) ---
message = visual.TextStim(
    win,
    text="Please look at the screen and remain seated.\nObserve the shapes; do not react or move.\nThis is a neutral baseline.\n\n",
    pos=(0, -0.35),
    color='white',
    height=0.025,
    wrapWidth=1.2
)

# Define geometric shapes (consistent scale, no clipping)
shapes = [
    visual.ShapeStim(win, vertices='cross', size=0.1, lineColor='white', fillColor=None),
    visual.Circle(win, radius=0.05, lineColor='white', fillColor=None),
    visual.Rect(win, width=0.1, height=0.1, lineColor='white', fillColor=None),
    visual.Polygon(win, edges=3, radius=0.06, lineColor='white', fillColor=None),  # triangle
    visual.Polygon(win, edges=4, radius=0.06, lineColor='white', fillColor=None),  # diamond/square
    visual.Polygon(win, edges=5, radius=0.06, lineColor='white', fillColor=None),
    visual.Polygon(win, edges=6, radius=0.06, lineColor='white', fillColor=None),
    visual.Circle(win, radius=0.06, lineColor='white', fillColor='white'),         # filled circle
    visual.Polygon(win, edges=8, radius=0.06, lineColor='white', fillColor=None),
    visual.Polygon(win, edges=7, radius=0.06, lineColor='white', fillColor=None),
    visual.Polygon(win, edges=9, radius=0.06, lineColor='white', fillColor=None),
    visual.Polygon(win, edges=10, radius=0.06, lineColor='white', fillColor=None)
]

# --- Timer setup ---
total_timer = core.Clock()
shape_timer = core.Clock()
shape_index = 0

while total_timer.getTime() < 120:  # 2 minutes
    # Early exit
    if 'space' in event.getKeys(keyList=['space']):
        win.close()
        core.quit()

    # Change shape every 6 seconds
    if shape_timer.getTime() >= 6:
        shape_index = (shape_index + 1) % len(shapes)
        shape_timer.reset()

    # Draw current shape + message
    shapes[shape_index].draw()
    message.draw()
    win.flip()

# --- End screen ---
end_text = visual.TextStim(
    win,
    text="Thank you. The baseline recording is complete.\n\nPress SPACE to exit.",
    color='white',
    height=0.03
)
end_text.draw()
win.flip()
event.waitKeys(keyList=['space'])

win.close()
core.quit()



