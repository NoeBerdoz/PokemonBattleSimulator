-- Create STAT table first as POKEMON_SPECIE depends on it
CREATE TABLE STAT
(
    ID              NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    HP              NUMBER
        CONSTRAINT NN_STAT_HP NOT NULL,
        CONSTRAINT CH_STAT_HP CHECK (HP >= 0 AND HP <= 255),
    SPEED           NUMBER
        CONSTRAINT NN_STAT_SPEED NOT NULL,
        CONSTRAINT CH_STAT_SPEED CHECK (SPEED >= 0 AND SPEED <= 255),
    ATTACK          NUMBER
        CONSTRAINT NN_STAT_ATTACK NOT NULL,
        CONSTRAINT CH_STAT_ATTACK CHECK (ATTACK >= 0 AND ATTACK <= 255),
    DEFENSE         NUMBER
        CONSTRAINT NN_STAT_DEFENSE NOT NULL,
        CONSTRAINT CH_STAT_DEFENSE CHECK (DEFENSE >= 0 AND DEFENSE <= 255),
    SPECIAL_ATTACK  NUMBER
        CONSTRAINT NN_STAT_SPECIAL_ATTACK NOT NULL,
        CONSTRAINT CH_STAT_SPECIAL_ATTACK CHECK (SPECIAL_ATTACK >= 0 AND SPECIAL_ATTACK <= 255),
    SPECIAL_DEFENSE NUMBER
        CONSTRAINT NN_STAT_SPECIAL_DEFENSE NOT NULL,
        CONSTRAINT CH_STAT_SPECIAL_DEFENSE CHECK (SPECIAL_DEFENSE >= 0 AND SPECIAL_DEFENSE <= 255)
);

-- Create POKEMON_SPECIE table with foreign key to STAT
CREATE TABLE POKEMON_SPECIE
(
    ID      NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    NAME    VARCHAR2(12)
        CONSTRAINT U_POKEMON_SPECIE_NAME UNIQUE
        CONSTRAINT NN_POKEMON_SPECIE_NAME NOT NULL,
    STAT_ID NUMBER
        CONSTRAINT NN_POKEMON_SPECIE_STAT_ID NOT NULL,
    CONSTRAINT FK_POKEMON_STAT FOREIGN KEY (STAT_ID) REFERENCES STAT (ID)
);

-- Create BATTLE table (BATTLE_POKEMON depends on it)
CREATE TABLE BATTLE
(
    ID                       NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    WINNER_BATTLE_POKEMON_ID NUMBER -- Foreign key added after the end of a battle
);

-- Create junction table BATTLE_POKEMON
CREATE TABLE BATTLE_POKEMON
(
    ID                NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    BATTLE_ID         NUMBER
        CONSTRAINT NN_BATTLE_POKEMON_BATTLE_ID NOT NULL,
    POKEMON_SPECIE_ID NUMBER
        CONSTRAINT NN_BATTLE_POKEMON_SPECIE_ID NOT NULL,
    CONSTRAINT FK_BATTLE_POKEMON_BATTLE FOREIGN KEY (BATTLE_ID) REFERENCES BATTLE (ID),
    CONSTRAINT FK_BATTLE_POKEMON_POKEMON FOREIGN KEY (POKEMON_SPECIE_ID) REFERENCES POKEMON_SPECIE (ID)
);

-- Add foreign key to BATTLE after BATTLE_POKEMON exists
ALTER TABLE BATTLE
    ADD CONSTRAINT FK_BATTLE_WINNER
        FOREIGN KEY (WINNER_BATTLE_POKEMON_ID) REFERENCES BATTLE_POKEMON (ID);

-- Create ROUND table with unique constraint
CREATE TABLE ROUND
(
    ID           NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    ROUND_NUMBER NUMBER
        CONSTRAINT NN_ROUND_NUMBER NOT NULL,
        CONSTRAINT CH_ROUND_NUMBER CHECK (ROUND_NUMBER > 0),
    BATTLE_ID    NUMBER
        CONSTRAINT NN_ROUND_BATTLE_ID NOT NULL,
    CONSTRAINT FK_ROUND_BATTLE FOREIGN KEY (BATTLE_ID) REFERENCES BATTLE (ID),
    CONSTRAINT UNIQUE_ROUND_PER_BATTLE UNIQUE (BATTLE_ID, ROUND_NUMBER)
);

SELECT * FROM ROUND;

-- Create ACTION table with multiple foreign keys
CREATE TABLE ACTION
(
    ID                       NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    ROUND_ID                 NUMBER
        CONSTRAINT NN_ACTION_ROUND_ID NOT NULL,
    ACTING_BATTLE_POKEMON_ID NUMBER
        CONSTRAINT NN_ACTION_ACTING_BATTLE_POKEMON_ID NOT NULL,
    TARGET_BATTLE_POKEMON_ID NUMBER
        CONSTRAINT NN_ACTION_TARGET_BATTLE_POKEMON_ID NOT NULL,
    ACTING_HP                NUMBER
        CONSTRAINT NN_ACTION_ACTING_HP NOT NULL,
    DAMAGE                   NUMBER
        CONSTRAINT NN_ACTION_DAMAGE NOT NULL,
    CONSTRAINT FK_ACTION_ROUND FOREIGN KEY (ROUND_ID) REFERENCES ROUND (ID),
    CONSTRAINT FK_ACTION_ACTING FOREIGN KEY (ACTING_BATTLE_POKEMON_ID) REFERENCES BATTLE_POKEMON (ID),
    CONSTRAINT FK_ACTION_TARGET FOREIGN KEY (TARGET_BATTLE_POKEMON_ID) REFERENCES BATTLE_POKEMON (ID)
);

-- Create BATTLE_LOG table that will store the XML
CREATE TABLE BATTLE_LOG
(
    ID           NUMBER GENERATED AS IDENTITY PRIMARY KEY,
    BATTLE_ID    NUMBER                                        NOT NULL,
    XML_DOCUMENT XMLTYPE,
    CREATED_AT   TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL, -- Records when the log was inserted
    XML_IS_VALID NUMBER(1, 0) DEFAULT 0 NOT NULL,
    CONSTRAINT CH_XML_IS_VALID CHECK (XML_IS_VALID IN (0, 1)),
    CONSTRAINT FK_BATTLE_LOG_BATTLE FOREIGN KEY (BATTLE_ID) REFERENCES BATTLE (ID)
) XMLTYPE XML_DOCUMENT STORE AS SECUREFILE BINARY XML;

-----------------------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CALCULATE_DAMAGE(
    p_attacker_attack IN STAT.ATTACK%type,
    p_defender_defense IN STAT.DEFENSE%type
) RETURN NUMBER IS
    v_base_damage   NUMBER;
    v_random_factor NUMBER;
BEGIN
    v_base_damage := (p_attacker_attack / p_defender_defense) * 10 + 2;

    -- Add slight randomness (85%-115% of calculated damage)
    v_random_factor := DBMS_RANDOM.VALUE(0.85, 1.15);

    -- Round to nearest whole number and ensure minimum 1 damage
    RETURN GREATEST(ROUND(v_base_damage * v_random_factor), 1);
END CALCULATE_DAMAGE;

CREATE OR REPLACE FUNCTION GET_BATTLE_LOG_XSD_VALIDATION(
    p_battle_log_id IN BATTLE_LOG.ID%type
) RETURN NUMBER IS
    v_is_valid NUMBER;
BEGIN

    SELECT XMLISVALID(XML_DOCUMENT, 'BattleLogSchemaV1.xsd')
    INTO v_is_valid
    FROM BATTLE_LOG
    WHERE ID = p_battle_log_id;

    RETURN v_is_valid;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('battle_id not found when validating XML for battle_log_id ' || p_battle_log_id);
        RETURN -1;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error validating XML for battle_log_id ' || p_battle_log_id || ': ' || SQLCODE || ' - ' || SQLERRM);
        RETURN -1;
END GET_BATTLE_LOG_XSD_VALIDATION;

-----------------------------------------------------------------------
-- PROCEDURES
-----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE LOG_ACTION(
    p_round_id IN NUMBER,
    p_acting_id IN NUMBER,
    p_target_id IN NUMBER,
    p_current_hp IN NUMBER,
    p_damage IN NUMBER
) IS
BEGIN
    INSERT INTO ACTION (ROUND_ID,
                        ACTING_BATTLE_POKEMON_ID,
                        TARGET_BATTLE_POKEMON_ID,
                        ACTING_HP,
                        DAMAGE)
    VALUES (p_round_id,
            p_acting_id,
            p_target_id,
            p_current_hp,
            p_damage);
END LOG_ACTION;

CREATE OR REPLACE PROCEDURE SIMULATE_BATTLE(
    p_pokemon_specie1_id IN NUMBER,
    p_pokemon_specie2_id IN NUMBER
) AS
    -- Battle variables
    v_battle_id        NUMBER;
    v_round_number     NUMBER := 1;
    v_round_id         NUMBER;
    v_winner_id        NUMBER;

    -- Pokémon variables
    v_pokemon1         BATTLE_POKEMON%ROWTYPE;
    v_pokemon2         BATTLE_POKEMON%ROWTYPE;
    v_attacker         BATTLE_POKEMON%ROWTYPE;
    v_defender         BATTLE_POKEMON%ROWTYPE;

    -- Pokemon names for output
    v_pokemon1_name    VARCHAR2(255);
    v_pokemon2_name    VARCHAR2(255);

    -- Stat variables
    v_hp1              NUMBER;
    v_hp2              NUMBER;
    v_attack1          NUMBER;
    v_attack2          NUMBER;
    v_defense1         NUMBER;
    v_defense2         NUMBER;
    v_speed1           NUMBER;
    v_speed2           NUMBER;

    -- Fight variables
    v_attacker_name    VARCHAR(255);
    v_defender_name    VARCHAR(255);
    v_attacker_id      NUMBER;
    v_defender_id      NUMBER;
    v_attacker_hp      NUMBER;
    v_defender_hp      NUMBER;
    v_attacker_attack  NUMBER;
    v_defender_attack  NUMBER;
    v_attacker_defense NUMBER;
    v_defender_defense NUMBER;

    -- Damage calculation
    v_damage           NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== STARTING NEW POKÉMON BATTLE ===');
    DBMS_OUTPUT.PUT_LINE('Initializing battle between Pokémon IDs: '
        || p_pokemon_specie1_id || ' and ' || p_pokemon_specie2_id);

    -- Get Pokemon names for output
    SELECT NAME INTO v_pokemon1_name FROM POKEMON_SPECIE WHERE ID = p_pokemon_specie1_id;
    SELECT NAME INTO v_pokemon2_name FROM POKEMON_SPECIE WHERE ID = p_pokemon_specie2_id;
    DBMS_OUTPUT.PUT_LINE('Battle participants: ' || v_pokemon1_name || ' VS ' || v_pokemon2_name);


    -- Initialize battle
    INSERT INTO BATTLE (ID, WINNER_BATTLE_POKEMON_ID)
    VALUES (DEFAULT, NULL)
    RETURNING ID INTO v_battle_id;
    DBMS_OUTPUT.PUT_LINE('Battle ID created: ' || v_battle_id);

    -- Insert battling Pokémon
    INSERT INTO BATTLE_POKEMON (BATTLE_ID, POKEMON_SPECIE_ID)
    VALUES (v_battle_id, p_pokemon_specie1_id)
    RETURNING ID INTO v_pokemon1.id;

    INSERT INTO BATTLE_POKEMON (BATTLE_ID, POKEMON_SPECIE_ID)
    VALUES (v_battle_id, p_pokemon_specie2_id)
    RETURNING ID INTO v_pokemon2.id;

    DBMS_OUTPUT.PUT_LINE('Battle Pokémon IDs assigned: ' ||
                         v_pokemon1.id || ' (' || v_pokemon1_name || ') and ' ||
                         v_pokemon2.id || ' (' || v_pokemon2_name || ')');

    -- Get initial stats
    SELECT s.HP, s.ATTACK, s.DEFENSE, s.SPEED
    INTO v_hp1, v_attack1, v_defense1, v_speed1
    FROM STAT s
             JOIN POKEMON_SPECIE ps ON ps.STAT_ID = s.ID
    WHERE ps.ID = p_pokemon_specie1_id;

    SELECT s.HP, s.ATTACK, s.DEFENSE, s.SPEED
    INTO v_hp2, v_attack2, v_defense2, v_speed2
    FROM STAT s
             JOIN POKEMON_SPECIE ps ON ps.STAT_ID = s.ID
    WHERE ps.ID = p_pokemon_specie2_id;

    DBMS_OUTPUT.PUT_LINE(v_pokemon1_name || ' has ' || v_hp1 || ' hp');
    DBMS_OUTPUT.PUT_LINE(v_pokemon2_name || ' has ' || v_hp2 || ' hp');

    -- Determine turn order
    IF v_speed1 >= v_speed2 THEN
        v_attacker := v_pokemon1;
        v_defender := v_pokemon2;

        v_attacker_name := v_pokemon1_name;
        v_attacker_id := v_pokemon1.ID;
        v_attacker_hp := v_hp1;
        v_attacker_attack := v_attack1;
        v_attacker_defense := v_defense1;

        v_defender_name := v_pokemon2_name;
        v_defender_id := v_pokemon2.ID;
        v_defender_hp := v_hp2;
        v_defender_attack := v_attack2;
        v_defender_defense := v_defense2;

        DBMS_OUTPUT.PUT_LINE(v_attacker_name || ' attacks first (higher speed)');
    ELSE
        v_attacker := v_pokemon2;
        v_defender := v_pokemon1;

        v_attacker_id := v_pokemon2.ID;
        v_attacker_name := v_pokemon2_name;
        v_attacker_hp := v_hp2;
        v_attacker_attack := v_attack2;
        v_attacker_defense := v_defense2;

        v_defender_id := v_pokemon1.ID;
        v_defender_name := v_pokemon1_name;
        v_defender_hp := v_hp1;
        v_defender_attack := v_attack1;
        v_defender_defense := v_defense1;

        DBMS_OUTPUT.PUT_LINE(v_attacker_name || ' attacks first (higher speed)');
    END IF;

    -- Battle loop
    WHILE v_attacker_hp > 0 AND v_defender_hp > 0
        LOOP
            DBMS_OUTPUT.PUT_LINE('--- ROUND ' || v_round_number || ' ---');

            -- Create round
            INSERT INTO ROUND (BATTLE_ID, ROUND_NUMBER)
            VALUES (v_battle_id, v_round_number)
            RETURNING ID INTO v_round_id;

-- First attack
            v_damage := CALCULATE_DAMAGE(
                    p_attacker_attack => v_attacker_attack,
                    p_defender_defense => v_defender_defense
                        );
            DBMS_OUTPUT.PUT_LINE(v_attacker_name || ' attacks ' || v_defender_name ||
                                 ' for ' || v_damage || ' damage');


            -- Log attacker action
            LOG_ACTION(v_round_id, v_attacker_id, v_defender_id, v_attacker_hp, v_damage);
            v_defender_hp := GREATEST(v_defender_hp - v_damage, 0);

            DBMS_OUTPUT.PUT_LINE(v_defender_name || ' HP reduced to ' || v_defender_hp);

            -- Second attack if defender still alive
            IF v_defender_hp > 0 THEN
                v_damage := CALCULATE_DAMAGE(
                        p_attacker_attack => v_defender_attack,
                        p_defender_defense => v_attacker_defense
                            );
                DBMS_OUTPUT.PUT_LINE(v_defender_name || ' attacks back ' || v_attacker_name ||
                                     ' for ' || v_damage || ' damage');

                -- Log defender action
                LOG_ACTION(v_round_id, v_defender_id, v_attacker_id, v_defender_hp, v_damage);
                v_attacker_hp := GREATEST(v_attacker_hp - v_damage, 0);

                DBMS_OUTPUT.PUT_LINE(v_attacker_name || ' HP reduced to ' || v_attacker_hp);
            END IF;

            v_round_number := v_round_number + 1;
        END LOOP;

    -- End of the battle, determine winner
    IF v_attacker_hp > 0 THEN
        DBMS_OUTPUT.PUT_LINE(v_defender_name || ' has fainted!');
        v_winner_id := v_attacker_id;
        DBMS_OUTPUT.PUT_LINE('=== BATTLE OVER ===');
        DBMS_OUTPUT.PUT_LINE(v_attacker_name || ' wins with ' || v_attacker_hp || ' HP remaining!');
    ELSE
        DBMS_OUTPUT.PUT_LINE(v_attacker_name || ' has fainted!');
        v_winner_id := v_defender_id;
        DBMS_OUTPUT.PUT_LINE('=== BATTLE OVER ===');
        DBMS_OUTPUT.PUT_LINE(v_defender_name || ' wins with ' || v_defender_hp || ' HP remaining!');
    END IF;

    -- Update battle with winner
    UPDATE BATTLE SET WINNER_BATTLE_POKEMON_ID = v_winner_id WHERE ID = v_battle_id;

    DBMS_OUTPUT.PUT_LINE('Battle completed successfully. Winner ID: ' || v_winner_id);

    DBMS_OUTPUT.PUT_LINE('Generating the battle history XML document...');
    -- Generate and store battle log
    GENERATE_BATTLE_LOG(p_battle_id => v_battle_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END SIMULATE_BATTLE;

CREATE OR REPLACE PROCEDURE GENERATE_BATTLE_LOG(
    p_battle_id IN BATTLE.ID%TYPE
)
AS
    v_xml_document  XMLTYPE;
    v_is_xml_valid NUMBER;
    v_battle_exists NUMBER;
    v_inserted_battle_log_id BATTLE_LOG.ID%type;
BEGIN
    -- Check if the battle doesn't exist to avoid errors
    SELECT COUNT(*)
    INTO v_battle_exists
    FROM BATTLE
    WHERE ID = p_battle_id;

    IF v_battle_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Battle ID ' || p_battle_id || ' not found.');
        RETURN; -- Exit if battle doesn't exist
    END IF;

    DBMS_OUTPUT.PUT_LINE('Generating XML log for Battle ID: ' || p_battle_id);

    -- Construct the XML using SQL/XML functions
    SELECT XMLElement("BattleLog",
                      XMLAgg( -- Aggregate all Round elements
                              XMLElement("Round",
                                         XMLAttributes(r.ROUND_NUMBER as
                                         "number"), -- Add the 'number' attribute to Round
                                         XMLAgg( -- Aggregate all Action elements within this round
                                                 XMLElement("Action",
                                                            XMLAttributes( -- Attributes for the Action element
                                                            ps_acting.NAME AS "pokemon", -- Acting Pokemon's name
                                                            a.ACTING_HP AS
                                                            "hp", -- Acting Pokemon's HP *before* this action
                                                            ps_target.NAME AS "target", -- Target Pokemon's name
                                                            a.DAMAGE AS "damage" -- Damage dealt in this action
                                                     )
                                                 ) ORDER BY
                                                 a.ID -- Order actions within a round chronologically (assuming ID sequence implies order)
                                         ) -- End XMLAgg for Actions
                              ) ORDER BY r.ROUND_NUMBER -- Order rounds chronologically
                      ) -- End XMLAgg for Rounds
           ) -- End XMLElement for BattleLog
    INTO v_xml_document
    FROM ROUND r
             JOIN ACTION a ON r.ID = a.ROUND_ID
             JOIN BATTLE_POKEMON bp_acting ON a.ACTING_BATTLE_POKEMON_ID = bp_acting.ID
             JOIN POKEMON_SPECIE ps_acting ON bp_acting.POKEMON_SPECIE_ID = ps_acting.ID
             JOIN BATTLE_POKEMON bp_target ON a.TARGET_BATTLE_POKEMON_ID = bp_target.ID
             JOIN POKEMON_SPECIE ps_target ON bp_target.POKEMON_SPECIE_ID = ps_target.ID
    WHERE r.BATTLE_ID = p_battle_id -- Filter for the specific battle
    GROUP BY r.ID, r.ROUND_NUMBER; -- Group actions by Round ID/Number to aggregate Actions per Round

    -- Insert the generated XML into the BATTLE_LOG table
    -- A new row is inserted each time, providing versioning via GENERATION_TIMESTAMP
    INSERT INTO BATTLE_LOG (BATTLE_ID, XML_DOCUMENT) -- GENERATION_TIMESTAMP gets DEFAULT value
    VALUES (p_battle_id, v_xml_document)
    RETURNING ID INTO v_inserted_battle_log_id;

    DBMS_OUTPUT.PUT_LINE('XML log generated and stored successfully with ID: ' || v_inserted_battle_log_id);

    -- Get the validation value of the XML against the XSD schema
    v_is_xml_valid := GET_BATTLE_LOG_XSD_VALIDATION(p_battle_log_id => v_inserted_battle_log_id);

    -- Update the BATTLE_LOG.XML_IS_VALID value based on result
    IF v_is_xml_valid = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Battle Log ' || p_battle_id || ' XML is valid');
        UPDATE BATTLE_LOG SET XML_IS_VALID = 1 WHERE ID = v_inserted_battle_log_id;
    ELSIF v_is_xml_valid = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Battle Log ' || p_battle_id || ' XML is NOT valid');
        UPDATE BATTLE_LOG SET XML_IS_VALID = 0 WHERE ID = v_inserted_battle_log_id;
    ELSE -- when v_is_xml_valid = -1 or else
        DBMS_OUTPUT.PUT_LINE('Error occurred during XML validation for Battle Log ID: ' || v_inserted_battle_log_id);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- This handles cases where a battle might exist but has no rounds/actions yet
        DBMS_OUTPUT.PUT_LINE('Warning: No rounds or actions found for Battle ID: ' || p_battle_id ||
                             '. No XML log generated.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error generating XML log for Battle ID ' || p_battle_id || ': ' || SQLERRM);
        RAISE;
END GENERATE_BATTLE_LOG;
/

-- Registration of the XSD Schema
BEGIN
    DBMS_XMLSCHEMA.registerSchema(
            SCHEMAURL => 'BattleLogSchemaV1.xsd', -- should normally be a URI
            SCHEMADOC => XMLType(
                    '<?xml version="1.0" encoding="UTF-8"?>
                    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">

                        <xs:simpleType name="PokemonNameType">
                            <xs:restriction base="xs:string">
                                <xs:pattern value="[A-Z][a-z]*"/>
                            </xs:restriction>
                        </xs:simpleType>

                        <xs:simpleType name="HpType">
                            <xs:restriction base="xs:nonNegativeInteger">
                                <xs:minInclusive value="0"/>
                                <xs:maxInclusive value="255"/>
                            </xs:restriction>
                        </xs:simpleType>

                        <xs:element name="BattleLog">
                            <xs:complexType>
                                <xs:sequence>
                                    <xs:element name="Round" maxOccurs="unbounded">
                                        <xs:complexType>
                                            <xs:sequence>
                                                <xs:element name="Action" maxOccurs="unbounded">
                                                    <xs:complexType>
                                                        <xs:attribute name="pokemon" type="PokemonNameType" use="required"/>
                                                        <xs:attribute name="hp" type="HpType" use="required"/>
                                                        <xs:attribute name="target" type="PokemonNameType" use="required"/>
                                                        <xs:attribute name="damage" type="xs:positiveInteger" use="required"/>
                                                    </xs:complexType>
                                                </xs:element>
                                            </xs:sequence>
                                            <xs:attribute name="number" type="xs:positiveInteger" use="required"/>
                                        </xs:complexType>
                                    </xs:element>
                                </xs:sequence>
                            </xs:complexType>
                        </xs:element>

                    </xs:schema>'
                         )
    );
    COMMIT;
END;

------------------------------------------------------------------------------------------------------------------------
    -- PLAYGROUND
------------------------------------------------------------------------------------------------------------------------

-- Helper loop to check if BATTLE_LOG.XML_DOCUMENT entry is valid against the XSD schema
DECLARE
    v_valid NUMBER;
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
