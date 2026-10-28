-- Testes CRUD e de integridade - Drogaria
-- Pré-requisito: executar Drogaria_Fisico.sql em um banco limpo.
-- Os dados ficam dentro de uma transação e são desfeitos no final.
-- Execute com um cliente MySQL que reconheça DELIMITER (por exemplo, mysql ou Workbench).

USE `drogaria`;

-- Rotinas auxiliares: capturam somente as rejeições esperadas pelos triggers.
DROP PROCEDURE IF EXISTS `tmp_teste_rejeita_recebimento`;
DROP PROCEDURE IF EXISTS `tmp_teste_rejeita_item_venda`;
DELIMITER $$
CREATE PROCEDURE `tmp_teste_rejeita_recebimento`(
  IN p_recebimento_id INT,
  IN p_item_compra_id INT,
  IN p_lote_id INT,
  IN p_cenario VARCHAR(100)
)
BEGIN
  DECLARE v_rejeitado BOOLEAN DEFAULT FALSE;
  DECLARE v_id INT DEFAULT NULL;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_rejeitado = TRUE;
    INSERT INTO `Item_Recebimento`
      (`quantidade_recebida`, `custo_unitario_real`, `fk_Recebimento_id`, `fk_Item_Compra_id`, `fk_Lote_id`)
    VALUES (0.125, 1.00, p_recebimento_id, p_item_compra_id, p_lote_id);
    SET v_id = LAST_INSERT_ID();
  END;

  IF v_rejeitado THEN
    SELECT CONCAT('PASSOU: ', p_cenario) AS `resultado_teste`;
  ELSE
    DELETE FROM `Item_Recebimento` WHERE `id` = v_id;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Falha: o recebimento incompatível foi aceito.';
  END IF;
END$$

CREATE PROCEDURE `tmp_teste_rejeita_item_venda`(
  IN p_venda_id INT,
  IN p_produto_id INT,
  IN p_item_receita_id INT,
  IN p_cenario VARCHAR(100)
)
BEGIN
  DECLARE v_rejeitado BOOLEAN DEFAULT FALSE;
  DECLARE v_id INT DEFAULT NULL;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_rejeitado = TRUE;
    INSERT INTO `Item_Venda`
      (`preco_unitario`, `quantidade`, `valor_total`, `fk_Venda_id`, `fk_Produto_id`, `fk_Item_Receita_id`)
    VALUES (1.00, 1.000, 1.00, p_venda_id, p_produto_id, p_item_receita_id);
    SET v_id = LAST_INSERT_ID();
  END;

  IF v_rejeitado THEN
    SELECT CONCAT('PASSOU: ', p_cenario) AS `resultado_teste`;
  ELSE
    DELETE FROM `Item_Venda` WHERE `id` = v_id;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Falha: o item de venda incompatível foi aceito.';
  END IF;
END$$
DELIMITER ;

START TRANSACTION;

-- Cadastros básicos.
INSERT INTO `Categoria` (`nome`, `descricao`) VALUES ('Medicamentos', 'Categoria de teste');
SET @categoria_id = LAST_INSERT_ID();
INSERT INTO `Fabricante` (`cnpj`, `razao_social`) VALUES ('11111111000111', 'Fabricante de teste');
SET @fabricante_id = LAST_INSERT_ID();
INSERT INTO `Fornecedor` (`cnpj`, `razao_social`) VALUES ('22222222000122', 'Fornecedor de teste');
SET @fornecedor_id = LAST_INSERT_ID();
INSERT INTO `Principio_Ativo` (`nome`, `descricao`) VALUES ('Principio A', 'Ativo de teste');
SET @principio_a_id = LAST_INSERT_ID();
INSERT INTO `Principio_Ativo` (`nome`, `descricao`) VALUES ('Principio B', 'Segundo ativo de teste');
SET @principio_b_id = LAST_INSERT_ID();
INSERT INTO `Perfil_Acesso` (`nome`, `descricao`) VALUES ('Atendente', 'Perfil de teste');
SET @perfil_id = LAST_INSERT_ID();
INSERT INTO `Cliente` (`cpf`, `data_cadastro`, `data_nascimento`, `nome`)
VALUES ('11111111111', CURRENT_DATE(), '2000-01-01', 'Cliente de teste');
SET @cliente_id = LAST_INSERT_ID();
INSERT INTO `Funcionario` (`data_admissao`, `nome`, `cargo`, `cpf`)
VALUES ('2025-01-10', 'Funcionario de teste', 'Farmaceutico', '22222222222');
SET @funcionario_id = LAST_INSERT_ID();

-- Dois medicamentos permitem testar incompatibilidade entre produto e lote/receita.
INSERT INTO `Produto`
  (`unidade_medida`, `estoque_minimo`, `descricao`, `nome`, `preco_venda`, `codigo_barras`, `fk_Categoria_id`, `fk_Fabricante_id`)
VALUES ('UN', 3.000, 'Primeiro produto de teste', 'Medicamento A', 10.00, '7890000000001', @categoria_id, @fabricante_id);
SET @produto_a_id = LAST_INSERT_ID();
INSERT INTO `Produto`
  (`unidade_medida`, `estoque_minimo`, `descricao`, `nome`, `preco_venda`, `codigo_barras`, `fk_Categoria_id`, `fk_Fabricante_id`)
VALUES ('UN', NULL, 'Segundo produto de teste', 'Medicamento B', 12.00, '7890000000002', @categoria_id, @fabricante_id);
SET @produto_b_id = LAST_INSERT_ID();
INSERT INTO `Medicamento` (`id`, `exige_receita`, `registro_anvisa`) VALUES (@produto_a_id, TRUE, 'ANV-TESTE-A');
SET @medicamento_a_id = @produto_a_id;
INSERT INTO `Medicamento` (`id`, `exige_receita`, `registro_anvisa`) VALUES (@produto_b_id, TRUE, 'ANV-TESTE-B');
SET @medicamento_b_id = @produto_b_id;
INSERT INTO `Lote` (`data_fabricacao`, `numero_lote`, `data_validade`, `fk_Produto_id`)
VALUES ('2026-01-01', 'LOTE-TESTE-A', '2027-12-31', @produto_a_id);
SET @lote_a_id = LAST_INSERT_ID();
INSERT INTO `Lote` (`data_fabricacao`, `numero_lote`, `data_validade`, `fk_Produto_id`)
VALUES ('2026-01-01', 'LOTE-TESTE-B', '2027-12-31', @produto_b_id);
SET @lote_b_id = LAST_INSERT_ID();
INSERT INTO `Medicamento_Principio_Ativo` (`fk_Principio_Ativo_id`, `fk_Medicamento_id`)
VALUES (@principio_a_id, @medicamento_a_id);
INSERT INTO `Medicamento_Principio_Ativo` (`fk_Principio_Ativo_id`, `fk_Medicamento_id`)
VALUES (@principio_b_id, @medicamento_b_id);

-- Compras, itens e recebimentos.
INSERT INTO `Compra` (`observacao`, `fk_Fornecedor_id`, `fk_Funcionario_id`)
VALUES ('Compra A de teste', @fornecedor_id, @funcionario_id);
SET @compra_a_id = LAST_INSERT_ID();
INSERT INTO `Item_Compra` (`preco_unitario`, `quantidade_solicitada`, `fk_Compra_id`, `fk_Produto_id`)
VALUES (10.00, 2.000, @compra_a_id, @produto_a_id);
SET @item_compra_a_id = LAST_INSERT_ID();
INSERT INTO `Recebimento` (`observacao`, `fk_Compra_id`, `fk_Funcionario_id`)
VALUES ('Recebimento A', @compra_a_id, @funcionario_id);
SET @recebimento_a_id = LAST_INSERT_ID();

INSERT INTO `Compra` (`observacao`, `fk_Fornecedor_id`, `fk_Funcionario_id`)
VALUES ('Compra B de teste', @fornecedor_id, @funcionario_id);
SET @compra_b_id = LAST_INSERT_ID();
INSERT INTO `Item_Compra` (`preco_unitario`, `quantidade_solicitada`, `fk_Compra_id`, `fk_Produto_id`)
VALUES (12.00, 2.000, @compra_b_id, @produto_b_id);
SET @item_compra_b_id = LAST_INSERT_ID();
INSERT INTO `Recebimento` (`observacao`, `fk_Compra_id`, `fk_Funcionario_id`)
VALUES ('Recebimento B', @compra_b_id, @funcionario_id);
SET @recebimento_b_id = LAST_INSERT_ID();

-- Passo 2: triggers devem rejeitar compra cruzada e lote de produto diferente.
CALL `tmp_teste_rejeita_recebimento`(@recebimento_a_id, @item_compra_b_id, @lote_b_id, 'recebimento e item de compras diferentes');
CALL `tmp_teste_rejeita_recebimento`(@recebimento_a_id, @item_compra_a_id, @lote_b_id, 'lote de produto diferente do item comprado');

-- Recebimento válido parcial seguido de conclusão; o trigger atualiza Compra.status.
INSERT INTO `Item_Recebimento`
  (`quantidade_recebida`, `custo_unitario_real`, `fk_Recebimento_id`, `fk_Item_Compra_id`, `fk_Lote_id`)
VALUES (1.000, 10.00, @recebimento_a_id, @item_compra_a_id, @lote_a_id);
SET @item_recebimento_a1_id = LAST_INSERT_ID();
SELECT 'COMPRA_A_APOS_RECEBIMENTO_PARCIAL' AS `verificacao`, `status`
FROM `Compra` WHERE `id` = @compra_a_id;
INSERT INTO `Item_Recebimento`
  (`quantidade_recebida`, `custo_unitario_real`, `fk_Recebimento_id`, `fk_Item_Compra_id`, `fk_Lote_id`)
VALUES (1.000, 10.00, @recebimento_a_id, @item_compra_a_id, @lote_a_id);
SET @item_recebimento_a2_id = LAST_INSERT_ID();
SELECT 'COMPRA_A_APOS_RECEBIMENTO_COMPLETO' AS `verificacao`, `status`
FROM `Compra` WHERE `id` = @compra_a_id;

-- Vendas, prescrições e itens relacionados.
INSERT INTO `Venda` (`observacao`, `status`, `fk_Funcionario_id`, `fk_Cliente_id`)
VALUES ('Venda A de teste', 'CONCLUIDA', @funcionario_id, @cliente_id);
SET @venda_a_id = LAST_INSERT_ID();
INSERT INTO `Venda` (`observacao`, `fk_Funcionario_id`, `fk_Cliente_id`)
VALUES ('Venda B de teste', @funcionario_id, @cliente_id);
SET @venda_b_id = LAST_INSERT_ID();
INSERT INTO `Venda` (`observacao`, `fk_Funcionario_id`, `fk_Cliente_id`)
VALUES ('Venda cancelada de teste', @funcionario_id, @cliente_id);
SET @venda_cancelada_id = LAST_INSERT_ID();
INSERT INTO `Prescritor` (`uf_registro`, `nome`, `registro_profissional`)
VALUES ('SP', 'Prescritor de teste', 'REG-TESTE-1');
SET @prescritor_id = LAST_INSERT_ID();
INSERT INTO `Receita` (`data_emissao`, `observacao`, `url_documento`, `tipo_documento`, `data_validade`, `fk_Venda_id`, `fk_Prescritor_id`)
VALUES (CURRENT_DATE(), 'Receita da venda A', 'https://example.invalid/receita-a.pdf', 'DIGITAL', DATE_ADD(CURRENT_DATE(), INTERVAL 1 YEAR), @venda_a_id, @prescritor_id);
SET @receita_a_id = LAST_INSERT_ID();
INSERT INTO `Receita` (`data_emissao`, `observacao`, `url_documento`, `tipo_documento`, `data_validade`, `fk_Venda_id`, `fk_Prescritor_id`)
VALUES (CURRENT_DATE(), 'Receita da venda B', 'https://example.invalid/receita-b.pdf', 'DIGITAL', DATE_ADD(CURRENT_DATE(), INTERVAL 1 YEAR), @venda_b_id, @prescritor_id);
SET @receita_b_id = LAST_INSERT_ID();
INSERT INTO `Item_Receita` (`posologia`, `observacao`, `quantidade_prescrita`, `fk_Receita_id`, `fk_Medicamento_id`)
VALUES ('1 unidade ao dia', 'Item A1', 2.000, @receita_a_id, @medicamento_a_id);
SET @item_receita_a1_id = LAST_INSERT_ID();
INSERT INTO `Item_Receita` (`posologia`, `observacao`, `quantidade_prescrita`, `fk_Receita_id`, `fk_Medicamento_id`)
VALUES ('1 unidade a cada 12 horas', 'Item A2', 2.000, @receita_a_id, @medicamento_b_id);
SET @item_receita_a2_id = LAST_INSERT_ID();
INSERT INTO `Item_Receita` (`posologia`, `observacao`, `quantidade_prescrita`, `fk_Receita_id`, `fk_Medicamento_id`)
VALUES ('1 unidade ao dia', 'Item B1', 1.000, @receita_b_id, @medicamento_b_id);
SET @item_receita_b1_id = LAST_INSERT_ID();

INSERT INTO `Item_Venda`
  (`preco_unitario`, `percentual_desconto`, `quantidade`, `valor_total`, `fk_Venda_id`, `fk_Produto_id`, `fk_Item_Receita_id`)
VALUES (10.00, 0.00, 1.000, 10.00, @venda_a_id, @produto_a_id, @item_receita_a1_id);
SET @item_venda_a_id = LAST_INSERT_ID();

-- Passo 2: triggers devem rejeitar produto divergente e receita de outra venda.
CALL `tmp_teste_rejeita_item_venda`(@venda_a_id, @produto_a_id, @item_receita_a2_id, 'produto diferente do medicamento prescrito');
CALL `tmp_teste_rejeita_item_venda`(@venda_a_id, @produto_b_id, @item_receita_b1_id, 'receita vinculada a outra venda');

-- Pagamento, estorno e cancelamento.
INSERT INTO `Pagamento` (`status`, `forma_pagamento`, `valor`, `fk_Venda_id`)
VALUES ('CONFIRMADO', 'PIX', 10.00, @venda_a_id);
SET @pagamento_id = LAST_INSERT_ID();
INSERT INTO `Estorno` (`motivo`, `valor`, `fk_Pagamento_id`)
VALUES ('Estorno parcial de teste', 2.00, @pagamento_id);
SET @estorno_id = LAST_INSERT_ID();
INSERT INTO `Cancelamento` (`motivo`, `fk_Funcionario_id`, `fk_Venda_id`)
VALUES ('Cancelamento de teste', @funcionario_id, @venda_cancelada_id);
SET @cancelamento_id = LAST_INSERT_ID();
UPDATE `Venda` SET `status` = 'CANCELADA' WHERE `id` = @venda_cancelada_id;

-- Acesso e contatos.
INSERT INTO `Usuario` (`login`, `ultimo_acesso`, `senha_hash`, `fk_Perfil_Acesso_id`, `fk_Funcionario_id`)
VALUES ('usuario_teste', NULL, 'hash-ficticio-de-teste', @perfil_id, @funcionario_id);
SET @usuario_id = LAST_INSERT_ID();
INSERT INTO `Telefone_Cliente` (`numero`, `tipo`, `fk_Cliente_id`) VALUES ('11999990001', 'CELULAR', @cliente_id);
SET @telefone_cliente_id = LAST_INSERT_ID();
INSERT INTO `Email_Cliente` (`endereco_email`, `tipo`, `fk_Cliente_id`) VALUES ('cliente@example.invalid', 'PESSOAL', @cliente_id);
SET @email_cliente_id = LAST_INSERT_ID();
INSERT INTO `Endereco_Cliente` (`logradouro`, `cep`, `cidade`, `bairro`, `complemento`, `uf`, `numero`, `fk_Cliente_id`)
VALUES ('Rua de Teste', '01001000', 'Sao Paulo', 'Centro', NULL, 'SP', '100', @cliente_id);
SET @endereco_cliente_id = LAST_INSERT_ID();
INSERT INTO `Telefone_Fornecedor` (`numero`, `tipo`, `fk_Fornecedor_id`) VALUES ('1133330001', 'COMERCIAL', @fornecedor_id);
SET @telefone_fornecedor_id = LAST_INSERT_ID();
INSERT INTO `Email_Fornecedor` (`endereco_email`, `tipo`, `fk_Fornecedor_id`) VALUES ('fornecedor@example.invalid', 'COMERCIAL', @fornecedor_id);
SET @email_fornecedor_id = LAST_INSERT_ID();

-- Movimentações positivas e negativas e ajuste de estoque.
INSERT INTO `Ajuste_Estoque` (`observacao`, `motivo`, `fk_Funcionario_id`)
VALUES ('Ajuste de teste', 'Contagem física', @funcionario_id);
SET @ajuste_id = LAST_INSERT_ID();
INSERT INTO `Movimentacao_Estoque` (`motivo`, `tipo_movimentacao`, `quantidade`, `fk_Lote_id`)
VALUES ('Entrada de teste', 'ENTRADA', 10.000, @lote_a_id);
SET @mov_entrada_id = LAST_INSERT_ID();
INSERT INTO `Movimentacao_Estoque` (`motivo`, `tipo_movimentacao`, `quantidade`, `fk_Lote_id`, `fk_Item_Venda_id`)
VALUES ('Venda de teste', 'SAIDA', 1.000, @lote_a_id, @item_venda_a_id);
SET @mov_saida_id = LAST_INSERT_ID();
INSERT INTO `Movimentacao_Estoque` (`motivo`, `tipo_movimentacao`, `quantidade`, `fk_Lote_id`, `fk_Ajuste_Estoque_id`)
VALUES ('Ajuste de teste', 'AJUSTE_SAIDA', 0.500, @lote_a_id, @ajuste_id);
SET @mov_ajuste_id = LAST_INSERT_ID();

-- Consultas de conferência (SELECT) dos fluxos principais.
SELECT c.`id` AS `compra_id`, c.`status`, ic.`quantidade_solicitada`,
       COALESCE(SUM(ir.`quantidade_recebida`), 0) AS `quantidade_recebida`
FROM `Compra` AS c
JOIN `Item_Compra` AS ic ON ic.`fk_Compra_id` = c.`id`
LEFT JOIN `Item_Recebimento` AS ir ON ir.`fk_Item_Compra_id` = ic.`id`
WHERE c.`id` = @compra_a_id
GROUP BY c.`id`, c.`status`, ic.`quantidade_solicitada`;
SELECT * FROM `vw_Estoque_Produto` WHERE `produto_id` = @produto_a_id;
SELECT v.`id` AS `venda_id`, v.`status`, p.`nome` AS `produto`, iv.`quantidade`, iv.`valor_total`, pg.`status` AS `status_pagamento`
FROM `Venda` AS v
JOIN `Item_Venda` AS iv ON iv.`fk_Venda_id` = v.`id`
JOIN `Produto` AS p ON p.`id` = iv.`fk_Produto_id`
LEFT JOIN `Pagamento` AS pg ON pg.`fk_Venda_id` = v.`id`
WHERE v.`id` = @venda_a_id;

-- Alterações (UPDATE): um exemplo em cada tabela do modelo.
UPDATE `Categoria` SET `descricao` = 'Categoria atualizada' WHERE `id` = @categoria_id;
UPDATE `Fabricante` SET `nome_fantasia` = 'Fabricante atualizado' WHERE `id` = @fabricante_id;
UPDATE `Fornecedor` SET `nome_fantasia` = 'Fornecedor atualizado' WHERE `id` = @fornecedor_id;
UPDATE `Principio_Ativo` SET `descricao` = 'Ativo atualizado' WHERE `id` = @principio_a_id;
UPDATE `Perfil_Acesso` SET `descricao` = 'Perfil atualizado' WHERE `id` = @perfil_id;
UPDATE `Cliente` SET `nome` = 'Cliente atualizado' WHERE `id` = @cliente_id;
UPDATE `Funcionario` SET `cargo` = 'Farmaceutico responsavel' WHERE `id` = @funcionario_id;
UPDATE `Produto` SET `preco_venda` = 11.00 WHERE `id` = @produto_a_id;
UPDATE `Medicamento` SET `registro_anvisa` = 'ANV-ATUALIZADO' WHERE `id` = @medicamento_a_id;
UPDATE `Lote` SET `data_fabricacao` = '2026-02-01' WHERE `id` = @lote_a_id;
UPDATE `Ajuste_Estoque` SET `observacao` = 'Ajuste revisado' WHERE `id` = @ajuste_id;
UPDATE `Compra` SET `observacao` = 'Compra revisada' WHERE `id` = @compra_a_id;
UPDATE `Item_Compra` SET `preco_unitario` = 10.50 WHERE `id` = @item_compra_a_id;
UPDATE `Recebimento` SET `observacao` = 'Recebimento revisado' WHERE `id` = @recebimento_a_id;
UPDATE `Item_Recebimento` SET `custo_unitario_real` = 10.25 WHERE `id` = @item_recebimento_a1_id;
UPDATE `Venda` SET `observacao` = 'Venda revisada' WHERE `id` = @venda_a_id;
UPDATE `Prescritor` SET `nome` = 'Prescritor atualizado' WHERE `id` = @prescritor_id;
UPDATE `Receita` SET `observacao` = 'Receita revisada' WHERE `id` = @receita_a_id;
UPDATE `Item_Receita` SET `posologia` = '1 unidade ao dia, conforme orientação' WHERE `id` = @item_receita_a1_id;
UPDATE `Item_Venda` SET `percentual_desconto` = 5.00, `valor_total` = 9.50 WHERE `id` = @item_venda_a_id;
UPDATE `Pagamento` SET `status` = 'PARCIALMENTE_ESTORNADO' WHERE `id` = @pagamento_id;
UPDATE `Estorno` SET `motivo` = 'Estorno parcial revisado' WHERE `id` = @estorno_id;
UPDATE `Cancelamento` SET `motivo` = 'Cancelamento revisado' WHERE `id` = @cancelamento_id;
UPDATE `Usuario` SET `ultimo_acesso` = CURRENT_TIMESTAMP WHERE `id` = @usuario_id;
UPDATE `Telefone_Cliente` SET `tipo` = 'CELULAR PRINCIPAL' WHERE `id` = @telefone_cliente_id;
UPDATE `Email_Cliente` SET `tipo` = 'PESSOAL PRINCIPAL' WHERE `id` = @email_cliente_id;
UPDATE `Endereco_Cliente` SET `complemento` = 'Sala 1' WHERE `id` = @endereco_cliente_id;
UPDATE `Telefone_Fornecedor` SET `tipo` = 'COMERCIAL PRINCIPAL' WHERE `id` = @telefone_fornecedor_id;
UPDATE `Email_Fornecedor` SET `tipo` = 'COMERCIAL PRINCIPAL' WHERE `id` = @email_fornecedor_id;
UPDATE `Movimentacao_Estoque` SET `observacao` = 'Movimentacao conferida' WHERE `id` = @mov_entrada_id;
UPDATE `Medicamento_Principio_Ativo` SET `fk_Principio_Ativo_id` = @principio_b_id
WHERE `fk_Principio_Ativo_id` = @principio_a_id AND `fk_Medicamento_id` = @medicamento_a_id;

-- Exclusões (DELETE) em ordem inversa das dependências; o ROLLBACK final restaura o estado inicial.
DELETE FROM `Movimentacao_Estoque` WHERE `id` IN (@mov_entrada_id, @mov_saida_id, @mov_ajuste_id);
DELETE FROM `Item_Venda` WHERE `id` = @item_venda_a_id;
DELETE FROM `Estorno` WHERE `id` = @estorno_id;
DELETE FROM `Pagamento` WHERE `id` = @pagamento_id;
DELETE FROM `Cancelamento` WHERE `id` = @cancelamento_id;
DELETE FROM `Item_Receita` WHERE `id` IN (@item_receita_a1_id, @item_receita_a2_id, @item_receita_b1_id);
DELETE FROM `Receita` WHERE `id` IN (@receita_a_id, @receita_b_id);
DELETE FROM `Item_Recebimento` WHERE `id` IN (@item_recebimento_a1_id, @item_recebimento_a2_id);
DELETE FROM `Recebimento` WHERE `id` IN (@recebimento_a_id, @recebimento_b_id);
DELETE FROM `Item_Compra` WHERE `id` IN (@item_compra_a_id, @item_compra_b_id);
DELETE FROM `Compra` WHERE `id` IN (@compra_a_id, @compra_b_id);
DELETE FROM `Medicamento_Principio_Ativo` WHERE `fk_Medicamento_id` IN (@medicamento_a_id, @medicamento_b_id);
DELETE FROM `Lote` WHERE `id` IN (@lote_a_id, @lote_b_id);
DELETE FROM `Ajuste_Estoque` WHERE `id` = @ajuste_id;
DELETE FROM `Medicamento` WHERE `id` IN (@medicamento_a_id, @medicamento_b_id);
DELETE FROM `Produto` WHERE `id` IN (@produto_a_id, @produto_b_id);
DELETE FROM `Telefone_Cliente` WHERE `id` = @telefone_cliente_id;
DELETE FROM `Email_Cliente` WHERE `id` = @email_cliente_id;
DELETE FROM `Endereco_Cliente` WHERE `id` = @endereco_cliente_id;
DELETE FROM `Telefone_Fornecedor` WHERE `id` = @telefone_fornecedor_id;
DELETE FROM `Email_Fornecedor` WHERE `id` = @email_fornecedor_id;
DELETE FROM `Usuario` WHERE `id` = @usuario_id;
DELETE FROM `Venda` WHERE `id` IN (@venda_a_id, @venda_b_id, @venda_cancelada_id);
DELETE FROM `Cliente` WHERE `id` = @cliente_id;
DELETE FROM `Fornecedor` WHERE `id` = @fornecedor_id;
DELETE FROM `Fabricante` WHERE `id` = @fabricante_id;
DELETE FROM `Categoria` WHERE `id` = @categoria_id;
DELETE FROM `Principio_Ativo` WHERE `id` IN (@principio_a_id, @principio_b_id);
DELETE FROM `Perfil_Acesso` WHERE `id` = @perfil_id;
DELETE FROM `Prescritor` WHERE `id` = @prescritor_id;
DELETE FROM `Funcionario` WHERE `id` = @funcionario_id;

ROLLBACK;
DROP PROCEDURE IF EXISTS `tmp_teste_rejeita_recebimento`;
DROP PROCEDURE IF EXISTS `tmp_teste_rejeita_item_venda`;

SELECT 'TESTES_CONCLUIDOS_SEM_PERSISTIR_DADOS' AS `resultado_final`;