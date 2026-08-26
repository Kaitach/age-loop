extends Node

var gold: int = 0
var science: int = 0
var materials: int = 0
var crystals: int = 0

var world: int = 1
var wave: int = 1

var current_era: String = "prehistoric"

var inventory: Array = []
var equipped_items: Dictionary = {}
var buildings: Dictionary = {}
var technologies: Dictionary = {}
var upgrades: Dictionary = {}

var current_research = null
