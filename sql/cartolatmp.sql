-- Adminer 4.2.0 MySQL dump

SET NAMES utf8;
SET time_zone = '+00:00';

USE `cartolatmp`;

DROP TABLE IF EXISTS `match`;
CREATE TABLE `match` (
  `team_id_home` int(2) NOT NULL,
  `team_id_away` int(2) NOT NULL,
  `date` date NOT NULL,
  KEY `team_id_home` (`team_id_home`),
  KEY `team_id_away` (`team_id_away`),
  CONSTRAINT `match_ibfk_1` FOREIGN KEY (`team_id_home`) REFERENCES `team` (`id`) ON DELETE NO ACTION,
  CONSTRAINT `match_ibfk_2` FOREIGN KEY (`team_id_away`) REFERENCES `team` (`id`) ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `player`;
CREATE TABLE `player` (
  `id` int(6) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `position` char(3) NOT NULL,
  `id_team` int(2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_team` (`id_team`),
  CONSTRAINT `player_ibfk_1` FOREIGN KEY (`id_team`) REFERENCES `team` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `round`;
CREATE TABLE `round` (
  `id` int(2) NOT NULL,
  `player_id` int(6) NOT NULL,
  `player_score` double NOT NULL,
  `player_value` double NOT NULL,
  `date` date NOT NULL,
  KEY `player_id` (`player_id`),
  CONSTRAINT `round_ibfk_3` FOREIGN KEY (`player_id`) REFERENCES `player` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `team`;
CREATE TABLE `team` (
  `id` int(2) NOT NULL AUTO_INCREMENT,
  `name` varchar(15) NOT NULL,
  `code` varchar(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- 2015-06-05 03:09:35
