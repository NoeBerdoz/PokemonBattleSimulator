-----------------------------------------------------------------------
-- Insert data script, if you don't want to use the Java app
-----------------------------------------------------------------------
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

----------------------------------------------------------------------------------------
-- Execute this to simulate a few battles, and check your console output while doing it
----------------------------------------------------------------------------------------
-- TURN ON SERVEROUTPUT BEFORE EXECUTING THIS TO SEE THE RESULTS IN YOUR CONSOLE

-- First let's generate a few battles
BEGIN
    simulate_battle(
            p_pokemon_specie1_id => 9, -- Blastoise
            p_pokemon_specie2_id => 6 -- Charizard
    );
    simulate_battle(
            p_pokemon_specie1_id => 1, -- Bulbasaur
            p_pokemon_specie2_id => 4 -- Charizard
    );
    -- Generating a battle with two same POKEMON_SPECIES, to prove the model usability
    simulate_battle(
            p_pokemon_specie1_id => 7, -- Squirtle
            p_pokemon_specie2_id => 7 -- Squirtle
    );
    simulate_battle(
            p_pokemon_specie1_id => 9, -- Blastoise
            p_pokemon_specie2_id => 6 -- Charizard
    );
    -- We can Generate a new battle with the same Pokemon as the previous battle, as we instanciate them as BATTLE_POKEMON
    simulate_battle(
            p_pokemon_specie1_id => 9, -- Blastoise
            p_pokemon_specie2_id => 6 -- Charizard
    );
    COMMIT;
END;

-- Now, to prove the versioning and the ability to regenerate an XML, let's generate battle logs of the first battle.
BEGIN
    generate_battle_log(p_battle_id => 1);
    generate_battle_log(p_battle_id => 1);
    COMMIT;
    -- There should be 3 BATTLE_LOG targeting BATTLE_ID 1, each with a different CREATE_AT value.
END;

-- Now try to modify an existing entry of XML_DOCUMENT to make it not valid against the XSD.
-- Or you can inject one invalid XML_DOCUMENT by doing this insert:
BEGIN
    INSERT INTO BATTLE_LOG (BATTLE_ID, XML_DOCUMENT)
    VALUES (5, '<BattleLog>
        <Round number="1">
            <Action pokemon="notValidNamePattern!!!" hp="78" target="Blastoise" damage="11"/>
            <Action pokemon="Blastoise" hp="68" target="Charizard" damage="11"/>
        </Round></BattleLog>');
    COMMIT;
END;

-- Then, you can use this helper loop to check all BATTLE_LOG.XML_DOCUMENT entries validity against the XSD schema
-- You should see that the last entry you made manually is invalid. The same logic is implemented in the function GET_BATTLE_LOG_XSD_VALIDATION
BEGIN
    FOR record IN (SELECT ID, XML_DOCUMENT, XMLISVALID(XML_DOCUMENT, 'BattleLogSchemaV1.xsd') AS IS_VALID
                   FROM BATTLE_LOG) LOOP
            IF record.IS_VALID = 1 THEN
                DBMS_OUTPUT.PUT_LINE('Battle Log ID ' || record.ID || ': XML is VALID.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Battle Log ID ' || record.ID || ': XML is INVALID.');
            END IF;
        END LOOP;
END;

-- You may now want to check all the data in the tables, here are the SELECT for all tables
SELECT * FROM BATTLE_LOG;
SELECT * FROM BATTLE;
SELECT * FROM ROUND;
SELECT * FROM ACTION;
SELECT * FROM BATTLE_POKEMON;
SELECT * FROM POKEMON_SPECIE;
SELECT * FROM STAT;