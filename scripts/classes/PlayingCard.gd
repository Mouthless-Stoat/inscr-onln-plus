extends Control

onready var deckContainer = get_node("/root/Main/DeckEdit/HBoxContainer/VBoxContainer/MainArea/VBoxContainer/DeckPreview/DeckContainer")
onready var previewCont = get_node("/root/Main/DeckEdit/HBoxContainer/CardPreview/PreviewContainer/")

onready var sigilDescPrefab = preload("res://packed/SigilDescription.tscn")
onready var allCardData = get_node("/root/Main/AllCards")
onready var fightManager = get_node("/root/Main/CardFight")
onready var slotManager = get_node("/root/Main/CardFight/CardSlots")

# State
var card_data = {}
var in_hand = true

# Stats
var health = -1
var attack = -1

func from_data(cdat):
	card_data = cdat
	
	$CardBody/VBoxContainer/Label.text = card_data.name
	$CardBody/VBoxContainer/Portrait.texture = load("res://gfx/pixport/" + card_data.name + ".png")
	
	# Update card costs and sigils
	draw_cost()
	draw_sigils()
	
	# Set stats
	attack = card_data["attack"]
	health = card_data["health"]
	draw_stats()
	
	# Enable interaction with the card
	$CardBody/Button.disabled = false


func draw_cost():
	if card_data["blood_cost"] > 0:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.texture.region = Rect2(
			28,
			16 * (card_data["blood_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BloodCost.visible = false
	
	if card_data["bone_cost"] > 0:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.texture.region = Rect2(
			1,
			16 * (card_data["bone_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/BoneCost.visible = false
		
	if card_data["energy_cost"] > 0:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.texture.region = Rect2(
			82,
			16 * (card_data["energy_cost"] - 1) + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/EnergyCost.visible = false
	
	# Mox cost BS
	if card_data["mox_cost"]:
		# Decide which mox to show
		var true_mox = 0
		
		var gmox = "green" in card_data["mox_cost"]
		var omox = "orange" in card_data["mox_cost"]
		var bmox = "blue" in card_data["mox_cost"]
		
		true_mox = moxIdx(gmox, omox, bmox)
		
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.visible = true
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture = $CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture.duplicate()
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.texture.region = Rect2(
			55,
			16 * true_mox + 1,
			26,
			15
		)
	else:
		$CardBody/VBoxContainer/Portrait/HBoxContainer/VBoxContainer/MoxCost.visible = false

func draw_sigils():
	# Sigils
	if len(card_data.sigils) > 0:
		$CardBody/VBoxContainer/HBoxContainer/Sigil.texture = load("res://gfx/sigils/" + card_data.sigils[0] + ".png")
		$CardBody/VBoxContainer/HBoxContainer/Sigil.visible = true
		if len(card_data.sigils) > 1:
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.visible = true
			$CardBody/VBoxContainer/HBoxContainer/Spacer3.visible = true
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.texture = load("res://gfx/sigils/" + card_data.sigils[1] + ".png")
		else:
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.texture = null
			$CardBody/VBoxContainer/HBoxContainer/Sigil2.visible = false
			$CardBody/VBoxContainer/HBoxContainer/Spacer3.visible = false
	else:
		$CardBody/VBoxContainer/HBoxContainer/Sigil.texture = null
		$CardBody/VBoxContainer/HBoxContainer/Sigil2.texture = null
		$CardBody/VBoxContainer/HBoxContainer/Sigil2.visible = false
		$CardBody/VBoxContainer/HBoxContainer/Spacer3.visible = false
		
# Garb
func moxIdx(gmox, omox, bmox) -> int:
	if gmox and omox and bmox:
		return 6
	if gmox and omox:
		return 5
	if omox and bmox:
		return 4
	if bmox and gmox:
		return 3
	if bmox:
		return 2
	if omox: 
		return 1
	if gmox:
		return 0
	return -1

func draw_stats():
	$CardBody/HBoxContainer/AtkScore.text = str(attack)
	$CardBody/HBoxContainer/HpScore.text = str(health)

# When card is clicked
func _on_Button_pressed():
	# Only allow raising while in hand
	if in_hand:
		# Disable hand interactions while in a non-interactable phase
		if not fightManager.state in [fightManager.GameStates.NORMAL, fightManager.GameStates.SACRIFICE]:
			return
		
		if self == get_parent().get_parent().raisedCard:
			lower()
			get_parent().get_parent().raisedCard = null
		elif in_hand:
			
			# Only raise if all costs are met
			if fightManager.bones < card_data["bone_cost"]:
				print("You need more bones!")
				return
			
			# Only raise if all costs are met
			if slotManager.get_available_blood() < card_data["blood_cost"]:
				print("You need more sacrifices!")
				return
			
			# Enter sacrifice mode if card needs sacs
			if card_data["blood_cost"] > 0:
				fightManager.state = fightManager.GameStates.SACRIFICE
			else:
				fightManager.state = fightManager.GameStates.NORMAL
			
			raise()
	
	# When on board
	else:
		
		# Am I about to be sacrificed
		if fightManager.state == fightManager.GameStates.SACRIFICE:
			if self in slotManager.sacVictims:
				slotManager.sacVictims.erase(self)
				$CardBody/SacOlay.visible = false
			else:
				slotManager.sacVictims.append(self)
				$CardBody/SacOlay.visible = true
				
				# Attempt a sacrifice
				slotManager.attempt_sacrifice()
				
			slotManager.rpc_id(fightManager.opponent, "set_sac_olay_vis", get_parent().get_position_in_parent(), $CardBody/SacOlay.visible)

# Animation
func raise():
	get_parent().get_parent().lower_all_cards()
	get_parent().get_parent().raisedCard = self
	
	$AnimationPlayer.play("Raise")
	
	# Show the opponent the card was raised
	get_parent().get_parent().rpc_id(fightManager.opponent, "raise_opponent_card", get_position_in_parent())
	
func lower():
	if self == get_parent().get_parent().raisedCard:
		$AnimationPlayer.play("Lower")
		
		get_parent().get_parent().rpc_id(fightManager.opponent, "lower_opponent_card", get_position_in_parent())	

# Move to origin of new parent
func move_to_parent(new_parent):
	# Get card out of hand if possible, and ensure it is not considered raised
	if new_parent.name != "PlayerHand":
		in_hand = false
	
	# Lower cards if just played by active player
	if get_parent().name == "PlayerHand":
		get_parent().get_parent().lower_all_cards()
	
	# Reset position, as expected to be raised when this happens
	$AnimationPlayer.play("RESET")
	
	var gPos = rect_global_position
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
	rect_position = Vector2.ZERO
	$CardBody.rect_global_position = gPos
	
	$Tween.interpolate_property($CardBody, "rect_position", $CardBody.rect_position, Vector2.ZERO, 0.1, Tween.TRANS_LINEAR)
	$Tween.start()


# Attack pass, the card has just been called on to attack
func attack_pass():
	if card_data["attack"] == 0:
		attack_callback()
		return
	
	
	slotManager.rpc_id(fightManager.opponent, "remote_card_anim", get_parent().get_position_in_parent(), "AttackRemote")
	$AnimationPlayer.play("Attack")

# Attack callback, get the next card to attack
func attack_callback():
	get_parent().get_parent().get_parent().attack_callback()

# This is called when the attack animation would "hit". tell the slot manager to make it happen
func attack_hit():
	get_parent().get_parent().get_parent().handle_attack(get_parent().get_position_in_parent())
