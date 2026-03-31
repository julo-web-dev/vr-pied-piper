extends Label3D

var score = 0

func increase_score():
	score += 1
	text = "Score: %s" % score
