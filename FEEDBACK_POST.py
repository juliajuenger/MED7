from psychopy import visual, core, event, gui
import csv
import time

# ---------------------------
# Participant Info
# ---------------------------
info = {"Participant ID": ""}
dlg = gui.DlgFromDict(dictionary=info, title="Experiment")
if not dlg.OK:
    core.quit()
participant_id = info["Participant ID"]

# ---------------------------
# Window
# ---------------------------
win = visual.Window(fullscr=True, units='norm', color='black', allowGUI=True)

# ---------------------------
# Materials
# ---------------------------
images_files = ["valence.png", "arousal.png", "control.png"]
image_labels = [
    ("Frustrating", "Enjoyable"),
    ("Calm", "Excited"),
    ("Controlled", "In control")
]

header_text = "Rate how you felt during the experience."

question_list = [
    "I feel like the interrogator responded naturally to me.",
    "I feel like the story transpired naturally according to my decisions.",
    "I feel like the interrogator knew how I was feeling.",
    "I understood the events in the story as though I were the character.",
    "I imagined being in my character’s situation.",
    "I felt like I was in my character's head.",
    "I cared about the consequences my character faced.",
    "I felt absorbed in the situation.",
    "I felt like I was really inside the scene.",
    "My attention was fully focused on what was happening."
]

num_sam = len(images_files)
num_items = len(question_list)
total_items = num_sam + num_items

# ---------------------------
# CSV Setup
# ---------------------------
filename = f"{participant_id}_responses.csv"
with open(filename, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["participant_id", "item", "rating", "rt"])

# ---------------------------
# Preload Images
# ---------------------------
preloaded_images = [visual.ImageStim(win, image=f, pos=(0,0), size=(1.2, None)) for f in images_files]

# ---------------------------
# Intro Screen
# ---------------------------
intro_text = visual.TextStim(win, text="Click the button below to begin.", color='white', font="Arial", height=0.07, pos=(0,0.1))
start_rect = visual.Rect(win, width=0.4, height=0.15, fillColor="grey", pos=(0,-0.2))
start_label = visual.TextStim(win, text="Start", color="white", font="Arial", height=0.06, pos=(0,-0.2))

intro_text.draw()
start_rect.draw()
start_label.draw()
win.flip()

mouse = event.Mouse(win=win)
while not mouse.isPressedIn(start_rect):
    pass

# ---------------------------
# Function to run a trial
# ---------------------------
def run_trial(item_text, slider_obj, draw_extra=None, index=1, show_agree_disagree=False):
    submitted = False
    rt_start = time.time()
    
    next_rect = visual.Rect(win, width=0.4, height=0.15, fillColor="dimgray", pos=(0,-0.8))
    next_label = visual.TextStim(win, text="Next", color="white", font="Arial", height=0.06, pos=(0,-0.8))
    
    header = visual.TextStim(win, text=header_text, pos=(0,0.75), height=0.08, color='white', font="Arial")
    progress = visual.TextStim(win, text=f"Item {index} of {total_items}", pos=(0,0.9), height=0.06, color='white', font="Arial")
    
    disagree_label = visual.TextStim(win, text="Disagree", color="white", font="Arial", height=0.05, pos=(-0.55, -0.35)) if show_agree_disagree else None
    agree_label = visual.TextStim(win, text="Agree", color="white", font="Arial", height=0.05, pos=(0.55, -0.35)) if show_agree_disagree else None
    
    while not submitted:
        progress.draw()
        header.draw()
        slider_obj.draw()
        if draw_extra:
            draw_extra()
        if show_agree_disagree:
            disagree_label = visual.TextStim(win, text="Disagree", color="white", font="Arial", height=0.05, pos=(-0.55, -0.28))
            agree_label = visual.TextStim(win, text="Agree", color="white", font="Arial", height=0.05, pos=(0.55, -0.28))
            disagree_label.draw()
            agree_label.draw()

        
        if slider_obj.getRating() is not None:
            next_rect.fillColor = "green"
        else:
            next_rect.fillColor = "dimgray"
        next_rect.draw()
        next_label.draw()
        win.flip()
        
        if slider_obj.getRating() is not None and mouse.isPressedIn(next_rect):
            submitted = True

    rt = time.time() - rt_start
    with open(filename, "a", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([participant_id, item_text, slider_obj.getRating(), rt])

# ---------------------------
# SAM Image Ratings
# ---------------------------
global_index = 1
for i, img_file in enumerate(images_files):
    def draw_image():
        preloaded_images[i].draw()
        left = visual.TextStim(win, text=image_labels[i][0], pos=(-0.75,0), color='white', font="Arial", height=0.07)
        right = visual.TextStim(win, text=image_labels[i][1], pos=(0.75,0), color='white', font="Arial", height=0.07)
        left.draw()
        right.draw()
    
    slider = visual.Slider(win, ticks=list(range(1,10)), labels=[str(n) for n in range(1,10)],
                           granularity=1, style="rating", pos=(0,-0.5), size=(1.2,0.1), labelHeight=0.05, color='white')
    
    run_trial(img_file, slider, draw_extra=draw_image, index=global_index)
    global_index +=1

# ---------------------------
# Questionnaire Items
# ---------------------------
for q in question_list:
    question_stim = visual.TextStim(win, text=q, wrapWidth=1.4, pos=(0,0.3), color='white', font="Arial", height=0.07)
    def draw_question():
        question_stim.draw()
    
    slider = visual.Slider(win, ticks=list(range(1,8)), labels=[str(n) for n in range(1,8)],
                           granularity=1, style="rating", pos=(0,-0.4), size=(1.1,0.1), labelHeight=0.06, color='white')
    
    run_trial(q, slider, draw_extra=draw_question, index=global_index, show_agree_disagree=True)
    global_index +=1

# ---------------------------
# End Screen
# ---------------------------
end_text = visual.TextStim(win, text="Thank you! Click the button below to exit.", color='white', font="Arial", height=0.07, pos=(0,0.1))
exit_rect = visual.Rect(win, width=0.4, height=0.15, fillColor="grey", pos=(0,-0.2))
exit_label = visual.TextStim(win, text="Exit", color="white", font="Arial", height=0.06, pos=(0,-0.2))
end_text.draw()
exit_rect.draw()
exit_label.draw()
win.flip()

while not mouse.isPressedIn(exit_rect):
    pass

win.close()
core.quit()
