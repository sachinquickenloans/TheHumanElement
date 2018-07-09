
USE BICommon
GO

BEGIN TRAN

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Sensitive_TMEngagement.TMEngmtSurveyDim
CREATE TABLE Sensitive_TMEngagement.TMEngmtSurveyDim
(
SurveyID int NOT NULL,
SurveyDateID int NOT NULL,
SurveyName varchar(100) NOT NULL,
SurveySeason varchar(50) NOT NULL,
RecordInsertDateTime datetime NOT NULL,
RecordInsertUserName varchar(100) NOT NULL,
ETLInsertBatchID int NOT NULL,

CONSTRAINT [PK_Sensitive_TMEngagement_TMEngmtSurveyDim] PRIMARY KEY CLUSTERED 
(
	[SurveyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyDim ADD  CONSTRAINT [DEF_TMEngmtSurveyDim_RecordInsertDateTime]  DEFAULT (sysdatetime()) FOR [RecordInsertDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyDim ADD  CONSTRAINT [DEF_TMEngmtSurveyDim_RecordInsertUserName]  DEFAULT (suser_sname()) FOR [RecordInsertUserName]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyDim ADD  CONSTRAINT [DEF_TMEngmtSurveyDim_ETLInsertBatchID]  DEFAULT ((10000)) FOR [ETLInsertBatchID]
GO

--Sensitive_TMEngagement.TMEngmtSurveyAnswerDim
CREATE TABLE Sensitive_TMEngagement.TMEngmtSurveyAnswerDim
(
AnswerID int NOT NULL,
AnswerDesc varchar(250) NULL,
Isactive bit NULL,
RecordInsertDateTime datetime NOT NULL,
RecordInsertUserName varchar(100) NOT NULL,
ETLInsertBatchID int NOT NULL,

CONSTRAINT [PK_Sensitive_TMEngagement_TMEngmtSurveyAnswerDim] PRIMARY KEY CLUSTERED 
(
	[AnswerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyAnswerDim ADD  CONSTRAINT [DEF_TMEngmtSurveyAnswerDim_RecordInsertDateTime]  DEFAULT (sysdatetime()) FOR [RecordInsertDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyAnswerDim ADD  CONSTRAINT [DEF_TMEngmtSurveyAnswerDim_RecordInsertUserName]  DEFAULT (suser_sname()) FOR [RecordInsertUserName]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyAnswerDim ADD  CONSTRAINT [DEF_TMEngmtSurveyAnswerDim_ETLInsertBatchID]  DEFAULT ((10000)) FOR [ETLInsertBatchID]
GO

--Sensitive_TMEngagement.TMEngmtSurveyQuestionDim
CREATE TABLE Sensitive_TMEngagement.TMEngmtSurveyQuestionDim
(
QuestionID int NOT NULL,
ShortQuestionDesc  varchar(100) NOT NULL,
LongQuestionDesc varchar(500) NOT NULL,
IsActive bit NULL,
QuestionGroupID int NULL,
RecordInsertDateTime datetime NOT NULL,
RecordUpdateDateTime datetime NOT NULL,
RecordInsertUserName varchar(100) NOT NULL,
ETLInsertBatchID int NOT NULL,
ETLUpdateBatchID int NOT NULL,

CONSTRAINT [PK_Sensitive_TMEngagement_TMEngmtSurveyQuestionDim] PRIMARY KEY CLUSTERED 
(
	[QuestionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyQuestionDim ADD  CONSTRAINT [DEF_TMEngmtSurveyQuestionDim_RecordInsertDateTime]  DEFAULT (sysdatetime()) FOR [RecordInsertDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyQuestionDim ADD  CONSTRAINT [DEF_TMEngmtSurveyQuestionDim_RecordInsertUserName]  DEFAULT (suser_sname()) FOR [RecordInsertUserName]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyQuestionDim ADD  CONSTRAINT [DEF_TMEngmtSurveyQuestionDim_RecordUpdateDateTime]  DEFAULT (sysdatetime()) FOR [RecordUpdateDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyQuestionDim ADD  CONSTRAINT [DEF_TMEngmtSurveyQuestionDim_ETLInsertBatchID]  DEFAULT ((10000)) FOR [ETLInsertBatchID]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyQuestionDim ADD  CONSTRAINT [DEF_TMEngmtSurveyQuestionDim_ETLUpdateBatchID]  DEFAULT ((10000)) FOR [ETLUpdateBatchID]
GO

--Sensitive_TMEngagement.TMEngmtSurveyGroupDim
CREATE TABLE Sensitive_TMEngagement.TMEngmtSurveyGroupDim
(
QuestionGroupID int NOT NULL,
GroupName varchar(50) NOT NULL,
RecordInsertDateTime datetime NOT NULL,
RecordInsertUserName varchar(100) NOT NULL,
ETLInsertBatchID int NOT NULL,

CONSTRAINT [PK_Sensitive_TMEngagement_TMEngmtSurveyGroupDim] PRIMARY KEY CLUSTERED 
(
	[QuestionGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyGroupDim ADD  CONSTRAINT [DEF_TMEngmtSurveyGroupDim_RecordInsertDateTime]  DEFAULT (sysdatetime()) FOR [RecordInsertDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyGroupDim ADD  CONSTRAINT [DEF_TMEngmtSurveyGroupDim_RecordInsertUserName]  DEFAULT (suser_sname()) FOR [RecordInsertUserName]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyGroupDim ADD  CONSTRAINT [DEF_TMEngmtSurveyGroupDim_ETLInsertBatchID]  DEFAULT ((10000)) FOR [ETLInsertBatchID]
GO


--Sensitive_TMEngagement.TMEngmtSurveyTeamMemberDim
CREATE TABLE Sensitive_TMEngagement.TMEngmtSurveyTeamMemberDim
(
TMLRelationID int NOT NULL,
CommonID int NOT NULL,
LeaderID int NOT NULL,
RecordInsertDateTime datetime NOT NULL,
RecordInsertUserName varchar(100) NOT NULL,
ETLInsertBatchID int NOT NULL,

CONSTRAINT [PK_Sensitive_TMEngagement_TMEngmtSurveyTeamMemberDim] PRIMARY KEY CLUSTERED 
(
	[TMLRelationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Data]
) ON [Data]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyTeamMemberDim ADD  CONSTRAINT [DEF_TMEngmtSurveyTeamMemberDim_RecordInsertDateTime]  DEFAULT (sysdatetime()) FOR [RecordInsertDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyTeamMemberDim ADD  CONSTRAINT [DEF_TMEngmtSurveyTeamMemberDim_RecordInsertUserName]  DEFAULT (suser_sname()) FOR [RecordInsertUserName]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyTeamMemberDim ADD  CONSTRAINT [DEF_TMEngmtSurveyTeamMemberDim_ETLInsertBatchID]  DEFAULT ((10000)) FOR [ETLInsertBatchID]
GO
--Sensitive_TMEngagement.lTMEngmtSurveyFact
CREATE TABLE Sensitive_TMEngagement.TMEngmtSurveyFact
(
TMLRelationID int NOT NULL,
SurveyID int NOT NULL,
QuestionID int NOT NULL,
AnswerID int NULL,
RecordInsertDateTime datetime NOT NULL,
RecordUpdateDateTime datetime NOT NULL,
RecordInsertUserName varchar(100) NOT NULL,
ETLInsertBatchID int NOT NULL,
ETLUpdateBatchID int NULL
) ON [Data]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyFact ADD  CONSTRAINT [DEF_TMEngmtSurveyFact_RecordInsertDateTime]  DEFAULT (sysdatetime()) FOR [RecordInsertDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyFact ADD  CONSTRAINT [DEF_TMEngmtSurveyFact_RecordInsertUserName]  DEFAULT (suser_sname()) FOR [RecordInsertUserName]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyFact ADD  CONSTRAINT [DEF_TMEngmtSurveyFact_RecordUpdateDateTime]  DEFAULT (sysdatetime()) FOR [RecordUpdateDateTime]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyFact ADD  CONSTRAINT [DEF_TMEngmtSurveyFact_ETLInsertBatchID]  DEFAULT ((10000)) FOR [ETLInsertBatchID]
GO

ALTER TABLE Sensitive_TMEngagement.TMEngmtSurveyFact ADD  CONSTRAINT [DEF_TMEngmtSurveyFact_ETLUpdateBatchID]  DEFAULT ((10000)) FOR [ETLUpdateBatchID]
GO
COMMIT

