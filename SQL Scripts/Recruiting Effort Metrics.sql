
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
			, wf4.Dt_1stStatusRecruiting_RecruiterPhoneInterview
			, wf4.Dt_1stStatusRecruiting_RecruiterFacetoFace
			, wf4.Dt_1stStatusRecruiting_LeaderPhoneInterview
			, wf4.Dt_1stStatusRecruiting_LeaderFacetoFace
			, wf4.Dt_1stStatusRecruiting_VirtualInterview
			, Dt_1stStatusRecruiting_VerbalOfferAccepted
			, Dt_1stStatusHired_InternallyTransferred
			, Recruiting_Dt1stInStat_RecruiterReviewAccepted
			, Recruiting_Dt1stInStat_RecruiterReviewDeclined
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
			LEFT JOIN BICommon.Prehire.ApplicantDim AS ad WITH (NOLOCK)
				ON wf.MergedApplicantID = ad.ApplicantID
			LEFT JOIN BICommon.Prehire.vwJob AS j WITH (NOLOCK)
				ON wf.WorkFlowID = j.JobID
            ) AS wf ON wf.RecruiterCommonID = p.CommonID
	UNPIVOT (
		StatusDt FOR WorkflowStatus IN 
			(wf.Dt1stPlaced_Bin_1stSubmission
				, wf.Dt_1stStatusRecruiting_RecruiterPhoneInterview
				, wf.Dt_1stStatusRecruiting_RecruiterFacetoFace
				, wf.Dt_1stStatusRecruiting_LeaderPhoneInterview
				, wf.Dt_1stStatusRecruiting_LeaderFacetoFace
				, wf.Dt_1stStatusRecruiting_VirtualInterview
				, wf.Dt_1stStatusRecruiting_VerbalOfferAccepted
				, wf.Dt_1stStatusHired_InternallyTransferred
				, wf.Recruiting_Dt1stInStat_RecruiterReviewAccepted
				, wf.Recruiting_Dt1stInStat_RecruiterReviewDeclined                
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
        WHEN s.WorkflowStatus = 'Dt1stPlaced_Bin_1stSubmission' 
				AND s.Source IN ('Recruiter Contact', 'Talent Strategist Contact', 'Associate Recruiter Contact')
				AND (s.DaysSinceLastWorkflow IS NULL OR s.DaysSinceLastWorkflow >= 180)
			THEN 'SourcedCandidate'
        WHEN s.WorkflowStatus = 'Dt1stPlaced_Bin_1stSubmission' 
                AND s.Source = 'Referral'
                AND s.DaysSinceLastWorkflow IS NULL
			THEN 'ReferredCandidate'
        WHEN s.WorkflowStatus IN ('Dt_1stStatusRecruiting_RecruiterPhoneInterview', 'Dt_1stStatusRecruiting_RecruiterFacetoFace')
			THEN 'RecruiterInterview'
        WHEN s.WorkflowStatus IN ('Dt_1stStatusRecruiting_LeaderPhoneInterview', 'Dt_1stStatusRecruiting_LeaderFacetoFace', 'Dt_1stStatusRecruiting_VirtualInterview')
			THEN 'LeaderInterview'
        WHEN s.WorkflowStatus = 'Dt_1stStatusRecruiting_VerbalOfferAccepted'
			THEN 'VOA'
        WHEN s.WorkflowStatus = 'Dt_1stStatusHired_InternallyTransferred'
			THEN 'InternalTransfer' 
        WHEN s.WorkflowStatus IN ('Recruiting_Dt1stInStat_RecruiterReviewAccepted', 'Recruiting_Dt1stInStat_RecruiterReviewDeclined')
			THEN 'ResumeReview'
		END AS 'EffortType'
    , CASE WHEN s.WorkflowStatus = 'Dt1stPlaced_Bin_1stSubmission' 
                AND s.Source IN ('Recruiter Contact', 'Talent Strategist Contact', 'Associate Recruiter Contact')
                AND (s.DaysSinceLastWorkflow IS NULL OR s.DaysSinceLastWorkflow >= 180)
			THEN 1 ELSE 0 END AS 'SourcedCandidate'
    , CASE WHEN s.WorkflowStatus = 'Dt1stPlaced_Bin_1stSubmission' 
                AND s.Source = 'Referral'
                AND s.DaysSinceLastWorkflow IS NULL
			THEN 1 ELSE 0 END AS 'ReferredCandidate'
    , CASE WHEN s.WorkflowStatus IN ('Dt_1stStatusRecruiting_RecruiterPhoneInterview', 'Dt_1stStatusRecruiting_RecruiterFacetoFace')
			THEN 1 ELSE 0 END AS 'RecruiterInterview'
    , CASE WHEN s.WorkflowStatus IN ('Dt_1stStatusRecruiting_LeaderPhoneInterview', 'Dt_1stStatusRecruiting_LeaderFacetoFace', 'Dt_1stStatusRecruiting_VirtualInterview')
			THEN 1 ELSE 0 END AS 'LeaderInterview'
    , CASE WHEN s.WorkflowStatus = 'Dt_1stStatusRecruiting_VerbalOfferAccepted'
			THEN 1 ELSE 0 END AS 'VOA'
    , CASE WHEN s.WorkflowStatus = 'Dt_1stStatusHired_InternallyTransferred'
			THEN 1 ELSE 0 END AS 'InternalTransfer'           
    , CASE WHEN s.WorkflowStatus IN ('Recruiting_Dt1stInStat_RecruiterReviewAccepted', 'Recruiting_Dt1stInStat_RecruiterReviewDeclined')
			THEN 1 ELSE 0 END AS 'ResumeReview'
	, 0 AS OutboundCall
	, 0 AS InboundCall
INTO #statusgroups
FROM #statuses AS s


--Add call data
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
	, 0 AS SourcedCandidate
	, 0 AS ReferredCandidate
	, 0 AS RecruiterInterview
	, 0 AS LeaderInterview
	, 0 AS VOA
	, 0 AS InternalTransfer
	, 0 AS ResumeReview
    , CASE WHEN cf.CallDirectionID = 1 THEN 1 ELSE 0 END AS OutboundCall
	, CASE WHEN Cf.CallDirectionID = 2 THEN 1 ELSE 0 END AS InboundCall
FROM #pop AS p
	LEFT JOIN BICallData.dbo.CallFact AS cf WITH (NOLOCK) 
		ON cf.CallEmployeeCommonID = p.CommonID 
			AND cf.CallFromPhoneNumberID <> 31999
			AND CONVERT(DATE, cf.StartDateTime) >= DATEADD(MONTH, -2, GETDATE()) -- look back 2 months
			AND cf.StartDateID >= p.MinRecruitingDtID
WHERE cf.StartDateTime IS NOT NULL
