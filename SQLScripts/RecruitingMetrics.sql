SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--Get population of recruiters
DROP TABLE IF EXISTS #pop
SELECT ue.CommonID
	, ue.FirstName + ' ' + ue.LastName AS 'Team Member'
	, ue.JobTitle AS Title
	, ue.SubTeam AS Team
	, uel.FirstName + ' ' + uel.LastName AS Leader
	, teamdates.MinRecruitingDtID
INTO #pop
FROM Ultipro.dbo.UltiproEmployee AS ue WITH (NOLOCK)
	LEFT JOIN Ultipro.dbo.UltiproEmployee AS uel WITH (NOLOCK)
		ON uel.EmployeeID = ue.ManagerEmpId
	LEFT JOIN (
		SELECT tb.CommonID
			, MIN(tb.ActiveStartDtID) AS MinRecruitingDtID
		FROM BICommon.TeamMember.TeamBridge AS tb WITH (NOLOCK)
		WHERE tb.TeamID = 129 --The Pulse
		GROUP BY tb.CommonID
	) AS teamdates ON teamdates.CommonID = ue.CommonID
WHERE ue.JobCode IN (10073, 95018, 95019, 95304, 95392, 99435, 99760, 100867, 100972, 101127, 101523, 101881
		, 101933, 101943, 101946, 102301, 102843, 103105, 103317, 103318, 103320, 103322, 103364, 103381) --Recruiters
	AND ue.EmployeeStatus <> 'T'
	AND ue.Company = 'Quicken Loans Inc.'


--Get workflow statuses from the last 2 months for each req that the recruiter is assigned to
DROP TABLE IF EXISTS #statuses
SELECT unpvt.[Team Member]
	, unpvt.Title
	, unpvt.Team
	, unpvt.Leader
	, CONVERT(DATE, unpvt.StatusDt) AS EffortDt
	, unpvt.WorkflowStatus
	, unpvt.Source
	, unpvt.DaysSinceLastWorkflow
INTO #statuses
FROM #pop AS p
	LEFT JOIN (
        SELECT wf.MergedApplicantID AS 'ApplicantID'
			, ad.RecruiterCommonID
			, j.JobID AS 'RequisitionID'
			, j.UltiProJobCode AS 'RequisitionJobCode' 
			, j.UltiproJobTitle AS 'RequisitionJobTitle'
			, j.BusinessArea AS 'RequisitionBusinessArea'
			, j.JobEmpTypeForApplicant AS 'RequisitionEmpType'
			, ad.StartDateTrackerDt AS 'StartDate'
			, wf6.Source
			, wf3.Dt1stPlaced_Bin_1stSubmission
		  , wf4.Dt_1stStatusScreening_ATC1
		  , wf4.Dt_1stStatusRecruiting_ATC1
		  , wf4.Dt_1stStatusSubmission_NewSourcedCandidate
		  , wf5.Sourcing_Dt1stInStat_InitialContact1
          , wf9.Dt_1stStatusScreening_ResReviewNotMovingForward
		  , wf4.Dt_1stStatusScreening_ScheduledAppointment
		  , wf4.Dt_1stStatusRecruiting_RecruiterFacetoFace
		  , wf4.Dt_1stStatusRecruiting_RecruiterPhoneInterview
		  , wf4.Dt_1stStatusRecruiting_LeaderPhoneInterview
		  , wf4.Dt_1stStatusRecruiting_LeaderFacetoFace
		  , wf4.Dt_1stStatusRecruiting_VirtualInterview
		  , wf4.Dt_1stStatusRecruiting_VerbalOfferAccepted
		  , wf4.Dt_1stStatusRecruiting_FutureVerbalOfferAccepted
		  , wf5.Recruiting_Dt1stInStat_RecruiterReviewAccepted
          , wf5.Recruiting_Dt1stInStat_RecruiterReviewDeclined
          , wf5.Screening_Dt1stInStat_RecruiterReviewNeeded
		  , wf4.Dt_1stStatusRecruiting_ApprovedToOffer
		  , wf4.Dt_1stStatusSOA_WrittenOfferAccepted
		  , wf4.Dt_1stStatusHired_CompanytoCompany
          , wf4.Dt_1stStatusHired_ExternalHire
          , wf4.Dt_1stStatusHired_InternExtension
          , wf4.Dt_1stStatusHired_InterntoPerm
          , wf4.Dt_1stStatusHired_InternallyTransferred
          , wf4.Dt_1stStatusHired_ReHire
          , wf4.Dt_1stStatusHired_TempStarted
          , wf4.Dt_1stStatusHired_TemptoPerm
		  --, p3.Recruiter_First_Last AS person_Recruiter

			-- Get the number of days since the previous workflow to help decide if sourced or not
			, DATEDIFF(DAY,
				LAG(wf.WorkFlowLastUpdatedDate, 1) OVER (
					PARTITION BY wf.MergedApplicantID
					ORDER BY wf3.Dt1stPlaced_Bin_1stSubmission
					)
				, wf3.Dt1stPlaced_Bin_1stSubmission
				) AS DaysSinceLastWorkflow
        FROM BICommon.Prehire.vwMergedApplicantWorkFlow AS wf WITH (NOLOCK)
			LEFT JOIN SRC.ICIMS.vwWorkFlow3Current AS wf3 WITH (NOLOCK)
				ON wf.WorkFlowID = wf3.WorkflowID
					AND wf.MergedApplicantID = wf3.PersonSystemID
			LEFT JOIN SRC.ICIMS.vwWorkFlow4Current AS wf4 WITH (NOLOCK)
				ON wf.WorkFlowID = wf4.WorkflowID
					AND wf.MergedApplicantID = wf4.PersonSystemID  
			LEFT JOIN SRC.ICIMS.vwWorkFlow5Current AS wf5 WITH (NOLOCK)
				ON wf.WorkFlowID = wf5.WorkflowID
					AND wf.MergedApplicantID = wf5.PersonSystemID  
			LEFT JOIN SRC.ICIMS.vwWorkFlow6Current AS wf6 WITH (NOLOCK)
				ON wf.WorkFlowID = wf6.WorkflowID
					AND wf.MergedApplicantID = wf6.PersonSystemID
			LEFT JOIN SRC.ICIMS.vwWorkFlow9Current AS wf9 WITH (NOLOCK)
				ON wf.WorkFlowID = wf9.WorkflowID
					AND wf.MergedApplicantID = wf9.PersonSystemID
			LEFT JOIN BICommon.Prehire.ApplicantDim AS ad WITH (NOLOCK)
				ON wf.MergedApplicantID = ad.ApplicantID
				--LEFT JOIN SRC.ICIMS.PersonP3 P3
				--ON p3.systemid=wf3.personsystemID
			LEFT JOIN BICommon.Prehire.vwJob AS j WITH (NOLOCK)
				ON wf.WorkFlowID = j.JobID
            ) AS wf ON wf.RecruiterCommonID = p.CommonID
	UNPIVOT (
		StatusDt FOR WorkflowStatus IN 
			(wf.Dt1stPlaced_Bin_1stSubmission
		  , wf.Dt_1stStatusScreening_ATC1
		  , wf.Dt_1stStatusRecruiting_ATC1
		  , wf.Dt_1stStatusSubmission_NewSourcedCandidate
		  , wf.Sourcing_Dt1stInStat_InitialContact1
          , wf.Dt_1stStatusScreening_ResReviewNotMovingForward
		  , wf.Dt_1stStatusScreening_ScheduledAppointment
		  , wf.Dt_1stStatusRecruiting_RecruiterFacetoFace
		  , wf.Dt_1stStatusRecruiting_RecruiterPhoneInterview
		  , wf.Dt_1stStatusRecruiting_LeaderPhoneInterview
		  , wf.Dt_1stStatusRecruiting_LeaderFacetoFace
		  , wf.Dt_1stStatusRecruiting_VirtualInterview
		  , wf.Dt_1stStatusRecruiting_VerbalOfferAccepted
		  , wf.Dt_1stStatusRecruiting_FutureVerbalOfferAccepted
		  , wf.Recruiting_Dt1stInStat_RecruiterReviewAccepted
          , wf.Recruiting_Dt1stInStat_RecruiterReviewDeclined
          , wf.Screening_Dt1stInStat_RecruiterReviewNeeded
		  , wf.Dt_1stStatusRecruiting_ApprovedToOffer
		  , wf.Dt_1stStatusSOA_WrittenOfferAccepted
		  , wf.Dt_1stStatusHired_CompanytoCompany
          , wf.Dt_1stStatusHired_ExternalHire
          , wf.Dt_1stStatusHired_InternExtension
          , wf.Dt_1stStatusHired_InterntoPerm
          , wf.Dt_1stStatusHired_InternallyTransferred
          , wf.Dt_1stStatusHired_ReHire
          , wf.Dt_1stStatusHired_TempStarted
          , wf.Dt_1stStatusHired_TemptoPerm              
			)
	) AS unpvt
WHERE CONVERT(DATE, unpvt.StatusDt) >= DATEADD(MONTH, -2, GETDATE()) --look back 2 months


--Group workflow statuses into higher-level categories for reporting
DROP TABLE IF EXISTS #statusgroups
SELECT s.[Team Member]
	, s.Title
	, s.Team
	, s.Leader
	, s.EffortDt
	, 0 AS CallDuration
	, CASE 

	WHEN s.WorkflowStatus IN ('Dt_1stStatusScreening_ATC1', 'Dt_1stStatusRecruiting_ATC1')
			THEN 'ATC1'
	WHEN s.WorkflowStatus IN ('Dt_1stStatusSubmission_NewSourcedCandidate', 'wf.Sourcing_Dt1stInStat_InitialContact1')
			THEN 'Sourcing'
	WHEN s.WorkflowStatus = 'Dt_1stStatusScreening_ResReviewNotMovingForward'
			THEN 'NRO'
	WHEN s.WorkflowStatus IN ('Dt_1stStatusScreening_ScheduledAppointment' , 'Dt_1stStatusRecruiting_RecruiterFacetoFace', 'Dt_1stStatusRecruiting_RecruiterPhoneInterview')
			THEN 'Scheduled IV'
	WHEN s.WorkflowStatus IN ('Dt_1stStatusRecruiting_LeaderPhoneInterview', 'Dt_1stStatusRecruiting_LeaderFacetoFace','Dt_1stStatusRecruiting_VirtualInterview')
			THEN 'Leader IV'
	WHEN s.WorkflowStatus IN ('Dt_1stStatusRecruiting_VerbalOfferAccepted', 'Dt_1stStatusRecruiting_FutureVerbalOfferAccepted')
			THEN 'VOA'
	WHEN s.WorkflowStatus = 'Screening_Dt1stInStat_RecruiterReviewNeeded'
			THEN 'RRN'
	WHEN s.WorkflowStatus = 'Recruiting_Dt1stInStat_RecruiterReviewAccepted'
			THEN 'RRA'
	WHEN s.WorkflowStatus = 'Recruiting_Dt1stInStat_RecruiterReviewDeclined'
			THEN 'RRD'
	WHEN s.WorkflowStatus = 'Dt_1stStatusRecruiting_ApprovedToOffer'
			THEN 'ATO'
	WHEN s.WorkflowStatus = 'Dt_1stStatusSOA_WrittenOfferAccepted'
			THEN 'WOA'
	WHEN s.WorkflowStatus IN ('wf.Dt_1stStatusHired_CompanytoCompany'
          , 'Dt_1stStatusHired_ExternalHire'
          , 'Dt_1stStatusHired_InternExtension'
          , 'Dt_1stStatusHired_InterntoPerm'
          , 'Dt_1stStatusHired_InternallyTransferred'
          , 'Dt_1stStatusHired_ReHire'
          , 'Dt_1stStatusHired_TempStarted'
          , 'Dt_1stStatusHired_TemptoPerm')
			THEN 'Hired'
        
		END AS 'EffortType'
	,CASE 

	WHEN s.WorkflowStatus IN ('Dt_1stStatusScreening_ATC1'
		  , 'Dt_1stStatusSubmission_NewSourcedCandidate'
		  , 'Sourcing_Dt1stInStat_InitialContact1'
          , 'Dt_1stStatusScreening_ResReviewNotMovingForward'
		  , 'Dt_1stStatusScreening_ScheduledAppointment'
		  , 'Dt_1stStatusRecruiting_LeaderPhoneInterview'
		  , 'Dt_1stStatusRecruiting_LeaderFacetoFace'
		  , 'Dt_1stStatusRecruiting_VirtualInterview'
		  , 'Dt_1stStatusRecruiting_VerbalOfferAccepted'
		  , 'Dt_1stStatusRecruiting_FutureVerbalOfferAccepted'
		  , 'Recruiting_Dt1stInStat_RecruiterReviewAccepted'
          , 'Recruiting_Dt1stInStat_RecruiterReviewDeclined'
          , 'Screening_Dt1stInStat_RecruiterReviewNeeded')
			THEN 1 ELSE 0 
			END AS AssociateRecruiterCredited
    ,CASE 

	WHEN s.WorkflowStatus IN ('Dt_1stStatusScreening_ATC1'
	      , 'Dt_1stStatusRecruiting_ATC1'
		  , 'Dt_1stStatusSubmission_NewSourcedCandidate'
		  , 'Sourcing_Dt1stInStat_InitialContact1'
          , 'Dt_1stStatusScreening_ResReviewNotMovingForward'
		  , 'Dt_1stStatusRecruiting_RecruiterFacetoFace'
		  , 'Dt_1stStatusRecruiting_RecruiterPhoneInterview'
		  , 'Dt_1stStatusRecruiting_LeaderPhoneInterview'
		  , 'Dt_1stStatusRecruiting_LeaderFacetoFace'
		  , 'Dt_1stStatusRecruiting_VirtualInterview'
		  , 'Dt_1stStatusRecruiting_VerbalOfferAccepted'
		  , 'Dt_1stStatusRecruiting_FutureVerbalOfferAccepted'
		  , 'Dt_1stStatusRecruiting_ApprovedToOffer'
		  , 'Dt_1stStatusSOA_WrittenOfferAccepted'
		  , 'Dt_1stStatusHired_CompanytoCompany'
          , 'Dt_1stStatusHired_ExternalHire'
          , 'Dt_1stStatusHired_InternExtension'
          , 'Dt_1stStatusHired_InterntoPerm'
          , 'Dt_1stStatusHired_InternallyTransferred'
          , 'Dt_1stStatusHired_ReHire'
          , 'Dt_1stStatusHired_TempStarted'
          , 'Dt_1stStatusHired_TemptoPerm')
			THEN 1 ELSE 0 
			END AS RecruiterCredited
	,CASE 

	WHEN s.WorkflowStatus IN ('Dt_1stStatusScreening_ResReviewNotMovingForward'
		  , 'Dt_1stStatusScreening_ScheduledAppointment'
		  , 'Dt_1stStatusRecruiting_LeaderPhoneInterview'
		  , 'Dt_1stStatusRecruiting_LeaderFacetoFace'
		  , 'Dt_1stStatusRecruiting_VirtualInterview'
		  , 'Dt_1stStatusRecruiting_VerbalOfferAccepted'
		  , 'Dt_1stStatusRecruiting_FutureVerbalOfferAccepted'
		  , 'Recruiting_Dt1stInStat_RecruiterReviewAccepted'
          , 'Recruiting_Dt1stInStat_RecruiterReviewDeclined')
			THEN 1 ELSE 0 
			END AS ReferralAdvocateCredited
	,CASE 

	WHEN s.WorkflowStatus IN ('Dt_1stStatusScreening_ResReviewNotMovingForward'
		  , 'Dt_1stStatusScreening_ScheduledAppointment'
		  , 'Dt_1stStatusRecruiting_LeaderPhoneInterview'
		  , 'Dt_1stStatusRecruiting_LeaderFacetoFace'
		  , 'Dt_1stStatusRecruiting_VirtualInterview'
		  , 'Dt_1stStatusRecruiting_VerbalOfferAccepted'
		  , 'Dt_1stStatusRecruiting_FutureVerbalOfferAccepted'
		  , 'Recruiting_Dt1stInStat_RecruiterReviewAccepted'
          , 'Recruiting_Dt1stInStat_RecruiterReviewDeclined')
			THEN 1 ELSE 0 
			END AS CareerCoachCredited
	, 0 AS OutboundCall
	, 0 AS InboundCall
INTO #statusgroups
FROM #statuses AS s


--Add call data

DROP TABLE IF EXISTS #finalTable

Select X.* into #finalTable from 
(
SELECT sg.*
FROM #statusgroups AS sg
WHERE sg.EffortType IS NOT NULL
	AND sg.EffortDt IS NOT NULL
UNION ALL
SELECT p.[Team Member]
	, p.Title
	, p.Team
	, p.Leader
	, CONVERT(DATE, cf.StartDateTime) AS EffortDate
    , cf.Duration AS CallDuration
	, CASE WHEN cf.CallDirectionID = 1 THEN 'OutboundCall' ELSE 'InboundCall' END AS EffortType
	,0 AS AssociateRecruiterCredited
    ,0 AS RecruiterCredited
	,0 AS ReferralAdvocateCredited
	,0 AS CareerCoachCredited
    , CASE WHEN cf.CallDirectionID = 1 THEN 1 ELSE 0 END AS OutboundCall
	, CASE WHEN Cf.CallDirectionID = 2 THEN 1 ELSE 0 END AS InboundCall
FROM #pop AS p
	LEFT JOIN BICallData.dbo.CallFact AS cf WITH (NOLOCK) 
		ON cf.CallEmployeeCommonID = p.CommonID 
			AND cf.CallFromPhoneNumberID <> 31999
			AND CONVERT(DATE, cf.StartDateTime) >= DATEADD(MONTH, -2, GETDATE()) -- look back 2 months
			AND cf.StartDateID >= p.MinRecruitingDtID
WHERE cf.StartDateTime IS NOT NULL
) X







Select [Team Member], [Title],[Team],[Leader],[EffortType],COUNT(*) As EffortCount from #finalTable

Group by [Team Member], [Title],[Team],[Leader],[EffortType]

Order by [Team Member],COUNT(*) desc
