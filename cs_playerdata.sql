-- phpMyAdmin SQL Dump
-- version 3.5.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Sep 21, 2014 at 02:23 PM
-- Server version: 5.5.24-log
-- PHP Version: 5.4.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `cs_playerdata`
--

-- --------------------------------------------------------

--
-- Table structure for table `cs_playerdata`
--

CREATE TABLE IF NOT EXISTS `cs_playerdata` (
  `playerID` int(7) NOT NULL AUTO_INCREMENT,
  `playerName` varchar(24) NOT NULL DEFAULT 'Not Defined',
  `playerPassword` varchar(129) NOT NULL DEFAULT 'Not Defined',
  `playerIP` varchar(16) NOT NULL DEFAULT 'Not Defined',
  `playerLoggedIn` int(1) NOT NULL DEFAULT '1',
  `playerAutoLog` int(1) NOT NULL DEFAULT '0',
  `playerScore` int(12) NOT NULL DEFAULT '0',
  `playerAdminLevel` int(5) NOT NULL DEFAULT '0',
  `playerVIPLevel` int(2) NOT NULL DEFAULT '0',
  `playerVIPCredits` int(5) NOT NULL DEFAULT '0',
  `playerKills` int(12) NOT NULL DEFAULT '0',
  `playerDeaths` int(12) NOT NULL DEFAULT '0',
  `playerHeadshots` int(12) NOT NULL DEFAULT '0',
  `playerShotsOnTarget` int(12) NOT NULL DEFAULT '0',
  `playerTotalShots` int(12) NOT NULL DEFAULT '0',
  `playerWins` int(7) NOT NULL DEFAULT '0',
  `playerLosses` int(7) NOT NULL DEFAULT '0',
  `playerMarks` int(12) NOT NULL DEFAULT '0',
  `playerTotalSecondsPlayed` int(12) NOT NULL DEFAULT '0',
  `playerTotalMinutesPlayed` int(12) NOT NULL DEFAULT '0',
  `playerTotalHoursPlayed` int(12) NOT NULL DEFAULT '0',
  `playerLastSession` varchar(24) NOT NULL DEFAULT 'xx:xx:xx',
  `playerTeamMessages` int(1) NOT NULL DEFAULT '1',
  `playerRegisteredOn` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `playerLastConnection` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `playerCookies` int(12) NOT NULL DEFAULT '20',
  PRIMARY KEY (`playerID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

CREATE TABLE IF NOT EXISTS `cs_adminChatLogs` (
  `playerName` varchar(24) NOT NULL DEFAULT '(null)',
  `playerID` int(3) NOT NULL DEFAULT '0',
  `playerAdminLevel` int(3) NOT NULL DEFAULT '1',
  `playerText` varchar(129) NOT NULL DEFAULT '(null)'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `cs_playerConnections` (
  `conID` int(12) NOT NULL AUTO_INCREMENT,
  `conName` varchar(24) NOT NULL DEFAULT '(null)',
  `conIP` varchar(32) NOT NULL DEFAULT '0.0.0.0',
  `conPlayerID` int(6) NOT NULL DEFAULT '0',
  `conType` varchar(24) NOT NULL DEFAULT 'Nil',
  `conReason` varchar(24) NOT NULL DEFAULT 'Nil',
  `conTS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`conID`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;


CREATE TABLE IF NOT EXISTS `cs_playerBans` (
  `banID` int(6) NOT NULL AUTO_INCREMENT,
  `banName` varchar(24) NOT NULL,
  `banIP` varchar(16) NOT NULL,
  `bannerName` varchar(24) NOT NULL,
  `banReason` varchar(40) NOT NULL,
  `banTime` int(10) NOT NULL DEFAULT '0',
  `banDay` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`banID`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `cs_unbanLogs` (
  `unbanID` int(12) NOT NULL AUTO_INCREMENT,
  `adminName` varchar(24) NOT NULL DEFAULT '(null)',
  `unbanData` varchar(32) NOT NULL DEFAULT '0.0.0.0',
  `unbanTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`unbanID`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `cs_chatLogs` (
  `playerName` varchar(24) NOT NULL DEFAULT '(null)',
  `playerID` int(3) NOT NULL DEFAULT '0',
  `playerText` varchar(129) NOT NULL DEFAULT '(null)',
  `textTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `cs_radioChatLogs` (
  `playerName` varchar(24) NOT NULL DEFAULT '(null)',
  `playerID` int(3) NOT NULL DEFAULT '0',
  `playerTeam` int(3) NOT NULL DEFAULT '0',
  `playerText` varchar(129) NOT NULL DEFAULT '(null)',
  `textTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `cs_privateMessageLogs` (
  `senderName` varchar(24) NOT NULL DEFAULT '(null)',
  `senderID` int(3) NOT NULL DEFAULT '0',
  `receiverName` varchar(24) NOT NULL DEFAULT '(null)',
  `receiverID` int(3) NOT NULL DEFAULT '0',
  `pmText` varchar(129) NOT NULL DEFAULT '(null)'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;