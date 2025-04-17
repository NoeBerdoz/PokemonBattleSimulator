INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (45, 45, 49, 49, 65, 65);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Bulbasaur', 1);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (60, 60, 62, 63, 80, 80);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Ivysaur', 2);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (80, 80, 82, 83, 100, 100);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Venusaur', 3);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (39, 65, 52, 43, 60, 50);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Charmander', 4);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (58, 80, 64, 58, 80, 65);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Charmeleon', 5);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (78, 100, 84, 78, 109, 85);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Charizard', 6);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (44, 43, 48, 65, 50, 64);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Squirtle', 7);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (59, 58, 63, 80, 65, 80);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Wartortle', 8);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (79, 78, 83, 100, 85, 105);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Blastoise', 9);
INSERT INTO STAT (HP, SPEED, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE) VALUES (45, 45, 30, 35, 20, 20);
INSERT INTO POKEMON_SPECIE (NAME, STAT_ID) VALUES ('Caterpie', 10);
COMMIT;

BEGIN
    simulate_battle(
            p_pokemon_specie1_id => 9, -- Blastoise
            p_pokemon_specie2_id => 6 -- Charizard
    );
    simulate_battle(
            p_pokemon_specie1_id => 1, -- Bulbasaur
            p_pokemon_specie2_id => 4 -- Charizard
    );
    -- Generating a battle with two same POKEMON_SPECIES to proove the model usability
    simulate_battle(
            p_pokemon_specie1_id => 7, -- Squirtle
            p_pokemon_specie2_id => 7 -- Squirtle
    );
    simulate_battle(
            p_pokemon_specie1_id => 9, -- Blastoise
            p_pokemon_specie2_id => 6 -- Charizard
    );
    simulate_battle(
            p_pokemon_specie1_id => 9, -- Blastoise
            p_pokemon_specie2_id => 6 -- Charizard
    );
    COMMIT;
END;

-- Example of new XML generation for a battle ID that already has an XML_BATTLE_LOG (to proof versioning)
BEGIN
    generate_battle_log(p_battle_id => 1);
    generate_battle_log(p_battle_id => 1);
    generate_battle_log(p_battle_id => 1);
    generate_battle_log(p_battle_id => 1);
    COMMIT;
END;

SELECT * FROM BATTLE_LOG;
SELECT * FROM BATTLE;
SELECT * FROM BATTLE_POKEMON;
SELECT * FROM POKEMON_SPECIE;
SELECT * FROM STAT;
SELECT * FROM ACTION;
SELECT * FROM ROUND;