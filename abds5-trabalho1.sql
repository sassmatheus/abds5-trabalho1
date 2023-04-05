-- 1. ******************************************************
-- A) Criação do usuário
CREATE USER admin WITH PASSWORD 'admin';
 
-- B) Criação do banco
--CASO TERMINAL: CREATE DATABASE abds5_trabalho1;

GRANT ALL PRIVILEGES ON DATABASE abds5_trabalho1 TO admin;

--ACESSAR COM: \c abds5_trabalho1
-- C) Criação das sequências
CREATE SEQUENCE paciente_id_paciente_seq START 1;
CREATE SEQUENCE medico_id_medico_seq START 1;
CREATE SEQUENCE atende_id_atende_seq START 1;
CREATE SEQUENCE cirurgia_id_cirurgia_seq START 1;

-- D) Criação das tabelas 
CREATE TABLE paciente (
  id_paciente SERIAL PRIMARY KEY,
  codigo VARCHAR(10) NOT NULL,
  nome VARCHAR(100) NOT NULL,
  idade INTEGER NOT NULL
);

CREATE TABLE medico (
  id_medico SERIAL PRIMARY KEY,
  crm VARCHAR(10) NOT NULL,
  nome VARCHAR(100) NOT NULL,
  especialidade VARCHAR(100) NOT NULL
);

CREATE TABLE atende (
  id_atende SERIAL PRIMARY KEY,
  id_paciente INTEGER REFERENCES paciente(id_paciente),
  id_medico INTEGER REFERENCES medico(id_medico),
  data DATE NOT NULL
);

CREATE TABLE cirurgia (
  id_cirurgia SERIAL PRIMARY KEY,
  codigo VARCHAR(10) NOT NULL,
  data DATE NOT NULL,
  descricao VARCHAR(200),
  id_paciente INTEGER REFERENCES paciente(id_paciente)
);

-------------------INSERINDO DADOS------------------------

-- Tabela paciente
INSERT INTO paciente (codigo, nome, idade)
VALUES ('P1', 'Ana Antunes', 31),
       ('P2', 'Bruno Buarque', 19),
       ('P3', 'Carla Cortez', 25);

-- Tabela médico
INSERT INTO medico (crm, nome, especialidade)
VALUES ('M1', 'Mariana Marques', 'Pediatria'),
       ('M2', 'Nivaldo Nascimento', 'Cardiologia'),
       ('M3', 'Olga Oliveira', 'Psiquiatria');

-- Tabela atende
INSERT INTO atende (id_paciente, id_medico, data)
VALUES (1, 1, '2023-01-11'),
       (3, 2, '2023-02-12'),
       (2, 3, '2023-03-13');
	   INSERT INTO ATENDE (id_paciente, id_medico, data) values (3, 3, '2023-04-14');

-- Tabela cirurgia
INSERT INTO cirurgia (codigo, data, descricao, id_paciente)
VALUES ('C1', '2023-03-26', 'Cirurgia de cardíaca', 1),
       ('C2', '2023-03-27', 'Cirurgia de plástica', 3),
       ('C3', '2023-03-28', 'Cirurgia de de hérnia', 2);


-- 2. *************************************************************
-- Função para nova cirurgia
CREATE OR REPLACE FUNCTION nova_cirurgia(
  p_codigo VARCHAR(10),
  p_data DATE,
  p_descricao VARCHAR(200),
  p_id_paciente INTEGER
) RETURNS VOID AS
$$
DECLARE
  v_paciente paciente%ROWTYPE;
BEGIN
  SELECT * INTO v_paciente FROM paciente WHERE id_paciente = p_id_paciente;
  INSERT INTO cirurgia (codigo, data, descricao, id_paciente)
  VALUES (p_codigo, p_data, p_descricao, p_id_paciente);
END;
$$
LANGUAGE plpgsql;
----------------------------------------------------
-- Testando:
-- SELECT nova_cirurgia('C4', '2023-04-05', 'Cirurgia de joelho', 2);

-- 3. *******************************************************
-- Função atendimentos
CREATE OR REPLACE FUNCTION atendimentos(
  p_data_inicial DATE,
  p_data_final DATE
) RETURNS SETOF RECORD AS
$$
DECLARE
  v_medico medico%ROWTYPE;
  v_qtd_atendimentos INTEGER;
BEGIN
  FOR v_medico IN SELECT * FROM medico LOOP
  
    SELECT COUNT(*) INTO v_qtd_atendimentos FROM atende
    WHERE id_medico = v_medico.id_medico
    AND data >= p_data_inicial
    AND data <= p_data_final;

    RETURN QUERY SELECT v_medico.nome, v_qtd_atendimentos;
  END LOOP;
  
END;
$$
LANGUAGE plpgsql
-- TESTANDO:
-- SELECT * FROM atendimentos('2023-02-01', '2023-04-14') AS (v_medico varchar, v_qtd_atendimentos int);

-- 4. *********************************************************************

-- Trigger que verifica a data da cirurgia
CREATE OR REPLACE FUNCTION verificar_data() RETURNS TRIGGER AS
$$
BEGIN
  IF NEW.data > CURRENT_DATE THEN
    RAISE EXCEPTION 'Impossível inserir cirurgia para uma data maior que a corrente!';
  END IF;
  
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- Criando o trigger na tabela cirurgia
CREATE TRIGGER trigger_verificar_data
BEFORE INSERT ON cirurgia
FOR EACH ROW
EXECUTE FUNCTION verificar_data();

-- Testando o trigger, tentado inserir uma cirurgia com data posterior à atual
INSERT INTO cirurgia (codigo, data, descricao, id_paciente) VALUES ('C9', '2023-04-06', 'Rinoplastia', 1);

