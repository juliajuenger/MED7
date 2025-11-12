from psychopy import visual, core, event, gui
import csv

# --- Participant info dialog ---
info = {"Participant ID": ""}
dlg = gui.DlgFromDict(dictionary=info, title="Experiment")
if not dlg.OK:
    core.quit()

participant_id = info["Participant ID"]

# --- Window (fullscreen) ---
win = visual.Window(fullscr=True, color='black', units='norm')  # full screen

# --- Images and labels ---
images = ["valence.png", "arousal.png", "control.png"]  # replace with your files
image_side_labels = [("Unhappy", "Happy"),
                     ("Calm", "Excited"),
                     ("Controlled", "In control")]

header_text = "Rate how you felt during the experience. Press SPACE after selection."

# --- CSV setup ---
filename = f"{participant_id}_responses.csv"
with open(filename, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(["participant_id", "image", "rating", "rt"])

# --- Intro ---
intro = visual.TextStim(win, text="Press SPACE to begin.", color='white', height=0.07)
intro.draw()
win.flip()
event.waitKeys(keyList=['space'])

# --- Trials ---
for i, img_file in enumerate(images):
    # Header
    header = visual.TextStim(win, text=header_text, pos=(0,0.7), color='white', height=0.08)
    
    # Image
    image_width = 1.2
    image = visual.ImageStim(win, image=img_file, pos=(0,0), size=(image_width, None))
    
    # Side labels, closer to image
    left_label_text, right_label_text = image_side_labels[i]
    left_label = visual.TextStim(win, text=left_label_text, pos=(-image_width/2 - 0.15, 0),
                                 color='white', height=0.07, alignHoriz='right')
    right_label = visual.TextStim(win, text=right_label_text, pos=(image_width/2 + 0.15, 0),
                                  color='white', height=0.07, alignHoriz='left')

    # Slider same width as image
    slider = visual.Slider(
        win,
        ticks=list(range(1,10)),
        labels=[str(n) for n in range(1,10)],
        labelHeight=0.05,
        style='rating',
        granularity=1,
        pos=(0,-0.5),
        size=(image_width,0.1),
        color='white',
        colorSpace='rgb'
    )

    # Wait for participant to submit rating
    submitted = False
    while not submitted:
        header.draw()
        image.draw()
        left_label.draw()
        right_label.draw()
        slider.draw()
        win.flip()
        keys = event.getKeys(keyList=['space'])
        if keys and slider.getRating() is not None:
            submitted = True

    # Save response
    with open(filename, 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([participant_id, img_file, slider.getRating(), slider.getRT()])

# --- End ---
thanks = visual.TextStim(win, text="Thank you! Press SPACE to exit.", color='white', height=0.07)
thanks.draw()
win.flip()
event.waitKeys(keyList=['space'])

win.close()
core.quit()
