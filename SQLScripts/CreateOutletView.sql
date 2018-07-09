USE [BICommon]
GO

/****** Object:  View [Sensitive_TMEngagement].[vwTMEngmtSurveyFact]    Script Date: 6/29/2018 9:14:39 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [Sensitive_TMEngagement].[vwTMEngmtSurveyFact]
AS

SELECT tmd.CommonID
       , tmd.LeaderID
       , sf.SurveyID
       , sd.SurveyDateID
       , sd.SurveySeason
       , qd.QuestionID
       , qd.ShortQuestionDesc
       , qd.LongQuestionDesc
       , ad.AnswerDesc
FROM BICommon.Sensitive_TMEngagement.TMEngmtSurveyFact AS sf WITH (NOLOCK)
       LEFT JOIN BICommon.Sensitive_TMEngagement.TMEngmtSurveyTeamMemberDim AS tmd WITH (NOLOCK)
              ON tmd.TMLRelationID = sf.TMLRelationID
       LEFT JOIN BICommon.Sensitive_TMEngagement.TMEngmtSurveyAnswerDim AS ad WITH (NOLOCK)
              ON ad.AnswerID = sf.AnswerID
       LEFT JOIN BICommon.Sensitive_TMEngagement.TMEngmtSurveyDim AS sd WITH (NOLOCK)
              ON sd.SurveyID = sf.SurveyID
       LEFT JOIN BICommon.Sensitive_TMEngagement.TMEngmtSurveyQuestionDim AS qd WITH (NOLOCK)
              ON qd.QuestionID = sf.QuestionID


