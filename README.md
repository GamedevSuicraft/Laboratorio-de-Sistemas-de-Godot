# Godot Modular Systems Library

Esta é uma biblioteca de sistemas modulares para Godot, concebida para acelerar o desenvolvimento de jogos (especialmente em Game Jams), permitindo reutilizar componentes desacoplados em projetos 2D ou 3D.

## Estrutura do Projeto

O projeto utiliza o padrão de **Composição sobre Herança**, onde a lógica é dividida em módulos independentes que comunicam através de Sinais e Recursos (`Resource`).

### Sistemas Principais

* **HealthComponent**: Sistema genérico de gestão de vida. Funciona em qualquer nó, independente de ser 2D ou 3D.
* **StatusEffect System**: 
	* `StatusEffect.gd` (Resource): Molde para definir dados de efeitos (ex: veneno, cura).
	* `StatusEffectManager.gd` (Node): Gestor de estado que controla a duração e os *ticks* dos efeitos ativos.
* **Inventory System**:
	* `GameItem.gd` (Resource): O contentor base para qualquer item.
	* `InventorySlot.gd` (Resource): Gestão de quantidades e limites de *stack*.
	* `InventoryComponent.gd` (Node): Componente de contentor que gere a coleção de itens.

## Como Utilizar

### 1. Sistema de Saúde
Adiciona o `HealthComponent` como filho do teu nó (ex: `CharacterBody2D`).
```gdscript
# No teu script de personagem
@onready var health = $HealthComponent

func _on_hit(damage: float):
	health.damage(damage)
