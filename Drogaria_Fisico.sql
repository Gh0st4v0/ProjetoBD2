-- Modelo fisico inicial - Drogaria
-- MySQL 8.0.16+ / InnoDB / utf8mb4
-- Este arquivo define a estrutura; nao executa CREATE DATABASE nem conecta a servidor.

CREATE SCHEMA IF NOT EXISTS `drogaria`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE `drogaria`;

CREATE TABLE `Categoria` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `descricao` TEXT NULL,
  `nome` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

CREATE TABLE `Fabricante` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `nome_fantasia` VARCHAR(120) NOT NULL,
  `cnpj` CHAR(14) NOT NULL,
  `razao_social` VARCHAR(150) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Fabricante_cnpj` UNIQUE (`cnpj`)
) ENGINE=InnoDB;

CREATE TABLE `Fornecedor` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `cnpj` CHAR(14) NOT NULL,
  `razao_social` VARCHAR(150) NOT NULL,
  `nome_fantasia` VARCHAR(120) NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Fornecedor_cnpj` UNIQUE (`cnpj`)
) ENGINE=InnoDB;

CREATE TABLE `Principio_Ativo` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(120) NOT NULL,
  `descricao` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

CREATE TABLE `Perfil_Acesso` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(80) NOT NULL,
  `descricao` TEXT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Perfil_Acesso_nome` UNIQUE (`nome`)
) ENGINE=InnoDB;

CREATE TABLE `Cliente` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `cpf` CHAR(11) NULL,
  `data_cadastro` DATE NOT NULL,
  `data_nascimento` DATE NULL,
  `nome` VARCHAR(120) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Cliente_cpf` UNIQUE (`cpf`)
) ENGINE=InnoDB;

CREATE TABLE `Funcionario` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_admissao` DATE NOT NULL,
  `nome` VARCHAR(120) NOT NULL,
  `cargo` VARCHAR(80) NOT NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `cpf` CHAR(11) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Funcionario_cpf` UNIQUE (`cpf`)
) ENGINE=InnoDB;

CREATE TABLE `Produto` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `unidade_medida` VARCHAR(20) NOT NULL,
  `estoque_minimo` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `descricao` TEXT NULL,
  `nome` VARCHAR(120) NOT NULL,
  `preco_venda` DECIMAL(12,2) NOT NULL,
  `codigo_barras` VARCHAR(20) NULL,
  `fk_Categoria_id` INT NOT NULL,
  `fk_Fabricante_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Produto_codigo_barras` UNIQUE (`codigo_barras`),
  CONSTRAINT `ck_Produto_estoque_minimo` CHECK (`estoque_minimo` >= 0),
  CONSTRAINT `ck_Produto_preco_venda` CHECK (`preco_venda` >= 0),
  CONSTRAINT `fk_Produto_Categoria` FOREIGN KEY (`fk_Categoria_id`) REFERENCES `Categoria` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Produto_Fabricante` FOREIGN KEY (`fk_Fabricante_id`) REFERENCES `Fabricante` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Medicamento` (
  `id` INT NOT NULL,
  `exige_receita` BOOLEAN NOT NULL,
  `registro_anvisa` VARCHAR(20) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Medicamento_Produto` FOREIGN KEY (`id`) REFERENCES `Produto` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Lote` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_fabricacao` DATE NULL,
  `numero_lote` VARCHAR(50) NOT NULL,
  `data_validade` DATE NOT NULL,
  `fk_Produto_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Lote_Produto_numero` UNIQUE (`fk_Produto_id`, `numero_lote`),
  CONSTRAINT `ck_Lote_datas` CHECK (`data_fabricacao` IS NULL OR `data_validade` >= `data_fabricacao`),
  CONSTRAINT `fk_Lote_Produto` FOREIGN KEY (`fk_Produto_id`) REFERENCES `Produto` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Ajuste_Estoque` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observacao` TEXT NULL,
  `motivo` VARCHAR(150) NOT NULL,
  `fk_Funcionario_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Ajuste_Funcionario` FOREIGN KEY (`fk_Funcionario_id`) REFERENCES `Funcionario` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Compra` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_pedido` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observacao` TEXT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
  `fk_Fornecedor_id` INT NOT NULL,
  `fk_Funcionario_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Compra_status` CHECK (`status` IN ('PENDENTE','PARCIALMENTE_RECEBIDA','CONCLUIDA','CANCELADA')),
  CONSTRAINT `fk_Compra_Fornecedor` FOREIGN KEY (`fk_Fornecedor_id`) REFERENCES `Fornecedor` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Compra_Funcionario` FOREIGN KEY (`fk_Funcionario_id`) REFERENCES `Funcionario` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Item_Compra` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `preco_unitario` DECIMAL(12,2) NOT NULL,
  `quantidade_solicitada` DECIMAL(10,3) NOT NULL,
  `fk_Compra_id` INT NOT NULL,
  `fk_Produto_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Item_Compra_preco` CHECK (`preco_unitario` >= 0),
  CONSTRAINT `ck_Item_Compra_quantidade` CHECK (`quantidade_solicitada` > 0),
  CONSTRAINT `fk_Item_Compra_Compra` FOREIGN KEY (`fk_Compra_id`) REFERENCES `Compra` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Item_Compra_Produto` FOREIGN KEY (`fk_Produto_id`) REFERENCES `Produto` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Recebimento` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_recebimento` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observacao` TEXT NULL,
  `fk_Compra_id` INT NOT NULL,
  `fk_Funcionario_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Recebimento_Compra` FOREIGN KEY (`fk_Compra_id`) REFERENCES `Compra` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Recebimento_Funcionario` FOREIGN KEY (`fk_Funcionario_id`) REFERENCES `Funcionario` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Item_Recebimento` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `quantidade_recebida` DECIMAL(10,3) NOT NULL,
  `custo_unitario_real` DECIMAL(12,2) NOT NULL,
  `fk_Recebimento_id` INT NOT NULL,
  `fk_Item_Compra_id` INT NOT NULL,
  `fk_Lote_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Item_Recebimento_quantidade` CHECK (`quantidade_recebida` > 0),
  CONSTRAINT `ck_Item_Recebimento_custo` CHECK (`custo_unitario_real` >= 0),
  CONSTRAINT `fk_Item_Recebimento_Recebimento` FOREIGN KEY (`fk_Recebimento_id`) REFERENCES `Recebimento` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Item_Recebimento_Item_Compra` FOREIGN KEY (`fk_Item_Compra_id`) REFERENCES `Item_Compra` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Item_Recebimento_Lote` FOREIGN KEY (`fk_Lote_id`) REFERENCES `Lote` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Venda` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observacao` TEXT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'EM_ANDAMENTO',
  `fk_Funcionario_id` INT NOT NULL,
  `fk_Cliente_id` INT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Venda_status` CHECK (`status` IN ('EM_ANDAMENTO','CONCLUIDA','CANCELADA')),
  CONSTRAINT `fk_Venda_Funcionario` FOREIGN KEY (`fk_Funcionario_id`) REFERENCES `Funcionario` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Venda_Cliente` FOREIGN KEY (`fk_Cliente_id`) REFERENCES `Cliente` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Prescritor` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `uf_registro` CHAR(2) NOT NULL,
  `nome` VARCHAR(120) NOT NULL,
  `registro_profissional` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

CREATE TABLE `Receita` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_emissao` DATE NOT NULL,
  `observacao` TEXT NULL,
  `url_documento` VARCHAR(2048) NULL,
  `tipo_documento` VARCHAR(30) NOT NULL,
  `data_validade` DATE NULL,
  `fk_Venda_id` INT NOT NULL,
  `fk_Prescritor_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Receita_validade` CHECK (`data_validade` IS NULL OR `data_validade` >= `data_emissao`),
  CONSTRAINT `fk_Receita_Venda` FOREIGN KEY (`fk_Venda_id`) REFERENCES `Venda` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Receita_Prescritor` FOREIGN KEY (`fk_Prescritor_id`) REFERENCES `Prescritor` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Item_Receita` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `posologia` TEXT NOT NULL,
  `observacao` TEXT NULL,
  `quantidade_prescrita` DECIMAL(10,3) NOT NULL,
  `fk_Receita_id` INT NOT NULL,
  `fk_Medicamento_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Item_Receita_quantidade` CHECK (`quantidade_prescrita` > 0),
  CONSTRAINT `fk_Item_Receita_Receita` FOREIGN KEY (`fk_Receita_id`) REFERENCES `Receita` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Item_Receita_Medicamento` FOREIGN KEY (`fk_Medicamento_id`) REFERENCES `Medicamento` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Item_Venda` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `preco_unitario` DECIMAL(12,2) NOT NULL,
  `percentual_desconto` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `quantidade` DECIMAL(10,3) NOT NULL,
  `valor_total` DECIMAL(12,2) NOT NULL,
  `fk_Venda_id` INT NOT NULL,
  `fk_Produto_id` INT NOT NULL,
  `fk_Item_Receita_id` INT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Item_Venda_Item_Receita` UNIQUE (`fk_Item_Receita_id`),
  CONSTRAINT `ck_Item_Venda_preco` CHECK (`preco_unitario` >= 0),
  CONSTRAINT `ck_Item_Venda_desconto` CHECK (`percentual_desconto` >= 0 AND `percentual_desconto` <= 100),
  CONSTRAINT `ck_Item_Venda_quantidade` CHECK (`quantidade` > 0),
  CONSTRAINT `ck_Item_Venda_valor_total` CHECK (`valor_total` >= 0),
  CONSTRAINT `fk_Item_Venda_Venda` FOREIGN KEY (`fk_Venda_id`) REFERENCES `Venda` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Item_Venda_Produto` FOREIGN KEY (`fk_Produto_id`) REFERENCES `Produto` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Item_Venda_Item_Receita` FOREIGN KEY (`fk_Item_Receita_id`) REFERENCES `Item_Receita` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Pagamento` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `status` VARCHAR(30) NOT NULL DEFAULT 'CONFIRMADO',
  `forma_pagamento` VARCHAR(30) NOT NULL,
  `valor` DECIMAL(12,2) NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fk_Venda_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Pagamento_status` CHECK (`status` IN ('PENDENTE','CONFIRMADO','PARCIALMENTE_ESTORNADO','ESTORNADO')),
  CONSTRAINT `ck_Pagamento_forma` CHECK (`forma_pagamento` IN ('PIX','DINHEIRO','CARTAO_DEBITO','CARTAO_CREDITO')),
  CONSTRAINT `ck_Pagamento_valor` CHECK (`valor` > 0),
  CONSTRAINT `fk_Pagamento_Venda` FOREIGN KEY (`fk_Venda_id`) REFERENCES `Venda` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Estorno` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `motivo` TEXT NOT NULL,
  `valor` DECIMAL(12,2) NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fk_Pagamento_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Estorno_valor` CHECK (`valor` > 0),
  CONSTRAINT `fk_Estorno_Pagamento` FOREIGN KEY (`fk_Pagamento_id`) REFERENCES `Pagamento` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Cancelamento` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `motivo` TEXT NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fk_Funcionario_id` INT NOT NULL,
  `fk_Venda_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Cancelamento_Venda` UNIQUE (`fk_Venda_id`),
  CONSTRAINT `fk_Cancelamento_Funcionario` FOREIGN KEY (`fk_Funcionario_id`) REFERENCES `Funcionario` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Cancelamento_Venda` FOREIGN KEY (`fk_Venda_id`) REFERENCES `Venda` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Usuario` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `data_criacao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `login` VARCHAR(80) NOT NULL,
  `ultimo_acesso` DATETIME NULL,
  `senha_hash` VARCHAR(255) NOT NULL,
  `fk_Perfil_Acesso_id` INT NOT NULL,
  `fk_Funcionario_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `uq_Usuario_login` UNIQUE (`login`),
  CONSTRAINT `uq_Usuario_Funcionario` UNIQUE (`fk_Funcionario_id`),
  CONSTRAINT `fk_Usuario_Perfil` FOREIGN KEY (`fk_Perfil_Acesso_id`) REFERENCES `Perfil_Acesso` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Usuario_Funcionario` FOREIGN KEY (`fk_Funcionario_id`) REFERENCES `Funcionario` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Telefone_Cliente` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `numero` VARCHAR(20) NOT NULL,
  `tipo` VARCHAR(30) NOT NULL,
  `fk_Cliente_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Telefone_Cliente` FOREIGN KEY (`fk_Cliente_id`) REFERENCES `Cliente` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Email_Cliente` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `endereco_email` VARCHAR(254) NOT NULL,
  `tipo` VARCHAR(30) NOT NULL,
  `fk_Cliente_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Email_Cliente` FOREIGN KEY (`fk_Cliente_id`) REFERENCES `Cliente` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Endereco_Cliente` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `logradouro` VARCHAR(150) NOT NULL,
  `cep` CHAR(8) NOT NULL,
  `cidade` VARCHAR(100) NOT NULL,
  `bairro` VARCHAR(100) NOT NULL,
  `complemento` VARCHAR(100) NULL,
  `uf` CHAR(2) NOT NULL,
  `numero` VARCHAR(20) NOT NULL,
  `fk_Cliente_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Endereco_Cliente` FOREIGN KEY (`fk_Cliente_id`) REFERENCES `Cliente` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Telefone_Fornecedor` (
  `numero` VARCHAR(20) NOT NULL,
  `id` INT NOT NULL AUTO_INCREMENT,
  `tipo` VARCHAR(30) NOT NULL,
  `fk_Fornecedor_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Telefone_Fornecedor` FOREIGN KEY (`fk_Fornecedor_id`) REFERENCES `Fornecedor` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Email_Fornecedor` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `endereco_email` VARCHAR(254) NOT NULL,
  `tipo` VARCHAR(30) NOT NULL,
  `fk_Fornecedor_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_Email_Fornecedor` FOREIGN KEY (`fk_Fornecedor_id`) REFERENCES `Fornecedor` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Movimentacao_Estoque` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `motivo` VARCHAR(150) NULL,
  `tipo_movimentacao` VARCHAR(30) NOT NULL,
  `observacao` TEXT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `quantidade` DECIMAL(10,3) NOT NULL,
  `fk_Lote_id` INT NOT NULL,
  `fk_Ajuste_Estoque_id` INT NULL,
  `fk_Item_Venda_id` INT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_Movimentacao_tipo` CHECK (`tipo_movimentacao` IN ('ENTRADA','SAIDA','AJUSTE_ENTRADA','AJUSTE_SAIDA')),
  CONSTRAINT `ck_Movimentacao_quantidade` CHECK (`quantidade` > 0),
  CONSTRAINT `ck_Movimentacao_origem` CHECK (`fk_Ajuste_Estoque_id` IS NULL OR `fk_Item_Venda_id` IS NULL),
  CONSTRAINT `fk_Movimentacao_Lote` FOREIGN KEY (`fk_Lote_id`) REFERENCES `Lote` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Movimentacao_Ajuste` FOREIGN KEY (`fk_Ajuste_Estoque_id`) REFERENCES `Ajuste_Estoque` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_Movimentacao_Item_Venda` FOREIGN KEY (`fk_Item_Venda_id`) REFERENCES `Item_Venda` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `Medicamento_Principio_Ativo` (
  `fk_Principio_Ativo_id` INT NOT NULL,
  `fk_Medicamento_id` INT NOT NULL,
  PRIMARY KEY (`fk_Principio_Ativo_id`, `fk_Medicamento_id`),
  CONSTRAINT `fk_MPA_Principio_Ativo` FOREIGN KEY (`fk_Principio_Ativo_id`) REFERENCES `Principio_Ativo` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `fk_MPA_Medicamento` FOREIGN KEY (`fk_Medicamento_id`) REFERENCES `Medicamento` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;
