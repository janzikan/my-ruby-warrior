class Player

  # Minimal health that is needed so warrior can continue his journey.
  MIN_HEALTH = 7

  # Number of HP warrior will gain for each turn he rests.
  HEELING_RATE = 2

  # Damage the warrior can deal in close combat.
  MELEE_DAMAGE = 5

  def play_turn(warrior)
    # Warrior's current health.
    @health ||= warrior.health

    # Object that warrior is looking at.
    ahead = scan(warrior)

    # Object that warrior has behind his back.
    if behind = scan(warrior, :backward)
      @continue_exploring ||= true unless behind.wall?
    end

    # Heal.
    if is_hurt?(warrior) && !is_attacked?(warrior) && !see_stairs?(warrior)
      warrior.rest!
    # Enemy is near.
    elsif warrior.feel.enemy?
      warrior.attack!
    # Turn to the enemy if it attacking from behind.
    elsif is_attacked?(warrior) && !ranged_enemy?(ahead)
      warrior.pivot!
    # Rescue captives first.
    elsif behind && behind.captive?
      warrior.pivot!
    # Enemy in sight.
    elsif ahead && ahead.enemy?
      if ranged_enemy?(ahead)
        warrior.shoot!
      else
        enemy = ahead.unit

        # Turns needed to kill the enemy.
        turns_to_kill = (enemy.max_health.to_f / MELEE_DAMAGE).ceil

        # Damage that the enemy will deal before it dies.
        damage = (turns_to_kill - 1) * enemy.attack_power

        if damage >= warrior.health
          warrior.rest!
        else
          warrior.walk!
        end
      end
    # Rescue captive.
    elsif warrior.feel.captive?
      warrior.rescue!
    # Explore.
    else
      if (ahead && ahead.wall? && @continue_exploring) || (see_stairs?(warrior) && @continue_exploring)
        @continue_exploring = false
        warrior.pivot!
      else
        warrior.walk!
      end
    end

    @health = warrior.health
  end

  # Compare health between turns.
  def is_attacked?(warrior)
    warrior.health < @health
  end

  def is_hurt?(warrior, min_health = MIN_HEALTH)
    warrior.health < min_health
  end

  # Get the closest object that warrior is looking at in the given direction.
  def scan(warrior, direction = :forward)
    warrior.look(direction).each do |val|
      return val unless val.empty?
    end

    nil
  end

  # Check if the object is ranged enemy unit.
  def ranged_enemy?(object)
    return false unless object

    return true if object.unit && object.unit.respond_to?(:shoot_power)

    false
  end
  
  def see_stairs?(warrior, direction = :forward)
    warrior.look(direction).each do |val|
      return true if val.stairs?
    end

    false
  end

end
