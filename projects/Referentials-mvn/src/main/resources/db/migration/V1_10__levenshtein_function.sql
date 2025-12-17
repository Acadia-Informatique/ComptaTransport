-- Many versions can be found on the web, this one comes from 
-- https://packagist.org/packages/fza/mysql-doctrine-levenshtein-function
-- (17/12/2025)


DELIMITER ;;;

CREATE FUNCTION `LEVENSHTEIN`(s1 VARCHAR(255), s2 VARCHAR(255)) RETURNS int(11) DETERMINISTIC
BEGIN
    DECLARE s1_len, s2_len, i, j, c, c_temp, cost INT;
    DECLARE s1_char CHAR;
    DECLARE cv0, cv1 VARBINARY(256);
    SET s1_len = CHAR_LENGTH(s1), s2_len = CHAR_LENGTH(s2), cv1 = 0x00, j = 1, i = 1, c = 0;
    IF s1 = s2 THEN
        RETURN 0;
    ELSEIF s1_len = 0 THEN
        RETURN s2_len;
    ELSEIF s2_len = 0 THEN
        RETURN s1_len;
    ELSE
        WHILE j <= s2_len DO
            SET cv1 = CONCAT(cv1, UNHEX(HEX(j))), j = j + 1;
        END WHILE;
        WHILE i <= s1_len DO
            SET s1_char = SUBSTRING(s1, i, 1), c = i, cv0 = UNHEX(HEX(i)), j = 1;
            WHILE j <= s2_len DO
                SET c = c + 1;
                IF s1_char = SUBSTRING(s2, j, 1) THEN SET cost = 0; ELSE SET cost = 1; END IF;
                SET c_temp = CONV(HEX(SUBSTRING(cv1, j, 1)), 16, 10) + cost;
                IF c > c_temp THEN SET c = c_temp; END IF;
                SET c_temp = CONV(HEX(SUBSTRING(cv1, j+1, 1)), 16, 10) + 1;
                IF c > c_temp THEN SET c = c_temp; END IF;
                SET cv0 = CONCAT(cv0, UNHEX(HEX(c))), j = j + 1;
            END WHILE;
            SET cv1 = cv0, i = i + 1;
        END WHILE;
    END IF;
    RETURN c;
END;;;


 
-- added a function to make the thing work with short acronyms
CREATE FUNCTION `RANK_CUSTOMER_MATCH`(n1 VARCHAR(255), n2 VARCHAR(255)) RETURNS int(11) DETERMINISTIC
BEGIN
    DECLARE n1_len, n2_len, leven, relevance INT;
    DECLARE s1_norm, s2_norm VARCHAR(255);

	SET n1_len = CHAR_LENGTH(n1), n2_len = CHAR_LENGTH(n2);
	
	IF n1_len < 10 THEN
		SET s1_norm = REPLACE(UCASE(n1), ".", "");
		SET n1_len = CHAR_LENGTH(s1_norm);	
	ELSE
		SET s1_norm = UCASE(n1);
	END IF;

	IF n2_len < 10 THEN
		SET s2_norm = REPLACE(UCASE(n2), ".", "");
		SET n2_len = CHAR_LENGTH(s2_norm);	
	ELSE
		SET s2_norm = UCASE(n2);
	END IF;

	SET leven = LEVENSHTEIN(s1_norm, s2_norm);
	SET relevance = GREATEST(2, LEAST(n1_len, n2_len)/2); -- very empirical ;-)
	IF (leven > relevance) THEN
		RETURN 999;
	ELSE
		RETURN leven;
	END IF;
END;;;


DELIMITER ;

