************************************************************************************************************************************************************************************
***** FY14 Student Enrollment and Dosage Dataset Syntax.
************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
***** Before running:
*****     - Make sure to load the cyschoolhouse report (Total Student Dosage per IA - Mod, HQ Eval folder) into SPSS and that it is the current active file.
*****     - Make sure to save FY14 school name to ID translation in FY14 cross instrument source data file folder.
************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
***** FYI -- LINES 179 TO END OF FILE SHOULD BE IDENTICAL TO FILE FY14 STUDENT ENROLLMENT AND DOSAGE DATASET SYNTAX - TIME MACHINE.
************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************
***** Pull up and define source data files -- don't forget to make sure all ID variables are identical size/format.
************************************************************************************************************************************************************************************

***** First, give the active dataset (cyschoolhouse report data) a name.
DATASET NAME StudentEnrollDosage.

***** Pull up school name to ID translation file.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\cyschoolhouse FY14 List of Schools 2014.04.25.sav".
DATASET NAME SchoolIDs.

***** Pull up cyschoolhouse/cychannel school ID translation file.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 cyschoolhouse cychannel School ID Translation 2014.01.30.sav".
DATASET NAME SchoolIDTranslation.

***** Pull up cychannel dataset for DN variable.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\cychannel FY14 List of Schools 2014.03.11.sav".
DATASET NAME cychanSchoolInfo.

***** Pull up site/team-level enrollment and dosage goals.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14_Enrollment and Dosage Targets FINAL 2014.07.22.sav".
DATASET NAME SiteTeamEnrollDosage.

***** Pull up AmeriCorps grant ID translation file.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 cyschoolhouse AmeriCorps Grant ID Translation 2014.02.24.sav".
DATASET NAME ACGrantIDs.

***** Pull up AmeriCorps grant requirements.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 ACPM Summary for Progress Monitoring_eval 2014.06.19.sav".
DATASET NAME ACGoals.

***** Pull up Student ID translation file.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\dbo_RPT_STUDENT_MAIN 2014.05.30.sav".
DATASET NAME StPerfIDs.

***** Pull up literacy assessment performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY LIT ASSESS 2014.07.25.sav".
DATASET NAME LITAssessPerf.

***** Pull up math assessment performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY MTH ASSESS 2014.07.25.sav".
DATASET NAME MTHAssessPerf.

***** Pull up ELA course grade performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY ELA CG 2014.07.25.sav".
DATASET NAME ELACGPerf.

***** Pull up math course grade performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY MTH CG 2014.07.28.sav".
DATASET NAME MTHCGPerf.

***** Pull up attendance performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY ATT 2014.07.25.sav".
DATASET NAME ATTPerf.

***** Pull up behavior rubric performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY BEH RUBRIC 2014.07.25.sav".
DATASET NAME BEHRUBPerf.

***** Pull up behavior school-based performance data.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 EOY BEH SCHOOL BASED 2014.07.25.sav".
DATASET NAME BEHSCHPerf.

***** Pull up Diplomas Now Attendance and Behavior dataset.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 Diplomas Now Attendance Behavior Data 2014.07.24.sav".
DATASET NAME DNATTBEH.

***** Pull up DESSA dataset.
GET FILE = "Z:\Cross Instrument\FY14\Source Data\FY14 Final DESSA Dataset 6.25.14 - with IDs.sav".
DATASET NAME DESSA.

************************************************************************************************************************************************************************************
***** Activate and prep student enrollment dosage data for merge/aggregation.
************************************************************************************************************************************************************************************

***** Activate student enrollment/dosage dataset.
DATASET ACTIVATE StudentEnrollDosage.

************************************************************************************************************************************************************************************
***** For student/section level data.
************************************************************************************************************************************************************************************
***** Rename variables for ease of analysis.
RENAME VARIABLES (Location = Location) (Program = Program) (StudentStudentName = StudentName) (StudentGrade = StudentGrade)
(LocalStudentID = LocalStudentID) (InSchoolExtendedLearning = InSchELT) (EnrollmentDate = EnrollDate) (ExitDate = ExitDate) (StudentELALiteracy = IALIT)
(StudentMath = IAMTH) (StudentAttendance = IAATT) (StudentBehavior = IABEH) (StudentNumberofIndicatorAreas = IATOT)
(StudentSectionStudentSectionID = StudentSecID) (DosagetoDate = Dosage) (StudentSchoolName = School) (StudentStudentIDAutoNumber = cyStudentID)
(IndicatorArea = IndicatorArea).
***** Delete unnecessary variables.
DELETE VARIABLES IATOT InSchELT Program.
************************************************************************************************************************************************************************************

***** Reformat student grade level variable so that it is numeric.
RECODE StudentGrade ("PK" = "-1") ("K" = "0") ("UN Ungraded" = "").
ALTER TYPE StudentGrade (F2.0).

***** Reformat Location=TULSA.
RECODE Location ("TULSA" = "Tulsa").
EXECUTE.

************************************************************************************************************************************************************************************
***** Aggregate file to IndicatorArea level.
************************************************************************************************************************************************************************************

SORT CASES BY Location (A) School (A) cyStudentID (A) LocalStudentID (A) IndicatorArea (A).

DATASET DECLARE StudentIAData.

AGGREGATE
   /OUTFILE = StudentIAData
   /BREAK = Location (A) School (A) cyStudentID (A) LocalStudentID (A) IndicatorArea (A)
   /StudentName = FIRST(StudentName)
   /TotalDosage = SUM(Dosage)
   /EnrollDate = MIN(EnrollDate)
   /ExitDateLatest = MAX(ExitDate)
   /ExitMissing = NUMISS(ExitDate)
   /StudentGrade = MEAN(StudentGrade)
   /IALIT = MEAN(IALIT)
   /IAMTH = MEAN(IAMTH)
   /IAATT = MEAN(IAATT)
   /IABEH = MEAN(IABEH).

DATASET ACTIVATE StudentIAData.

***** Calculate latest exit date (this calculation needs to be done in case a student has been exited from one section, but may still be enrolled in another section).
***** Note (7/21/14): for students missing exit dates, we're assuming an exit date of 7/1 (date of system close).
DO IF (ExitMissing > 0).
COMPUTE ExitDate = DATE.MDY(07,01,2014) /*XDATE.DATE($TIME)*/ .
ELSE IF (ExitMissing = 0).
COMPUTE ExitDate = ExitDateLatest.
END IF.
EXECUTE.

ALTER TYPE ExitDate (ADATE10).

***** Can't have blank index values for casestovars command, so need to fill in blank indicator areas -- Also can't have "/" in name, so need to recode "ELA/Literacy".
DO IF (IndicatorArea = "").
COMPUTE IndicatorArea = "OTH".
ELSE IF (IndicatorArea = "ELA/Literacy").
COMPUTE IndicatorArea = "LIT".
ELSE IF (IndicatorArea = "Math").
COMPUTE IndicatorArea = "MTH".
ELSE IF (IndicatorArea = "Attendance").
COMPUTE IndicatorArea = "ATT".
ELSE IF (IndicatorArea = "Behavior").
COMPUTE IndicatorArea = "BEH".
END IF.
EXECUTE.

***** No longer need original student enrollment and dosage dataset.
DATASET CLOSE StudentEnrollDosage.

************************************************************************************************************************************************************************************
***** Restructure data file so that each row is a unique student.
************************************************************************************************************************************************************************************

SORT CASES BY cyStudentID (A) IndicatorArea (A).
EXECUTE.

CASESTOVARS
 /ID=cyStudentID
	/FIXED = Location School LocalStudentID StudentName StudentGrade IALIT IAMTH IAATT IABEH
 /AUTOFIX = NO
 /INDEX= IndicatorArea
	/DROP = ExitDateLatest ExitMissing.

DATASET NAME FINALDATASET.

************************************************************************************************************************************************************************************
***** Calculate Days Enrolled variable.
************************************************************************************************************************************************************************************

DATASET ACTIVATE FINALDATASET.

***** Variable labels for existing variables.
VARIABLE LABELS IALIT "Indicator Area Assignment: ELA/Literacy"
   IAMTH "Indicator Area Assignment: Math"
   IAATT "Indicator Area Assignment: Attendance"
   IABEH "Indicator Area Assignment: Behavior"
   StudentGrade "Student Grade Level".
VALUE LABELS IALIT 0 "ELA/Literacy: Students Without an IA-Assignment"
   1 "ELA/Literacy: Students With an IA-Assignment".
VALUE LABELS IAMTH 0 "Math: Students Without an IA-Assignment"
   1 "Math: Students With an IA-Assignment".
VALUE LABELS IAATT 0 "Attendance: Students Without an IA-Assignment"
   1 "Attendance: Students With an IA-Assignment".
VALUE LABELS IABEH 0 "Behavior: Students Without an IA-Assignment"
   1 "Behavior: Students With an IA-Assignment".
EXECUTE.

*****Days Enrolled.
COMPUTE LITEnroll = DATEDIFF(ExitDate.LIT, EnrollDate.LIT, "days").
COMPUTE ATTEnroll = DATEDIFF(ExitDate.ATT, EnrollDate.ATT, "days").
COMPUTE MTHEnroll = DATEDIFF(ExitDate.MTH, EnrollDate.MTH, "days").
COMPUTE BEHEnroll = DATEDIFF(ExitDate.BEH, EnrollDate.BEH, "days").
COMPUTE OTHEnroll = DATEDIFF(ExitDate.OTH, EnrollDate.OTH, "days").

VARIABLE LABELS LITEnroll "Days enrolled in ELA/Literacy"
   ATTEnroll "Days enrolled in Attendance"
   MTHEnroll "Days enrolled in Math"
   BEHEnroll "Days enrolled in Behavior"
   OTHEnroll "Days enrolled in other CY programming (e.g. ASH)".
EXECUTE.

************************************************************************************************************************************************************************************
***** Merge in cyschoolhouse school IDs.
************************************************************************************************************************************************************************************

***** Prep school ID file for merge.
DATASET ACTIVATE SchoolIDs.
RENAME VARIABLES (AccountName = School) (LegacyID = cyschSchoolRefID) (Location = Location).
***** Reformat Location=TULSA.
RECODE Location ("TULSA" = "Tulsa").
EXECUTE.
SORT CASES BY Location (A) School (A).
EXECUTE.

***** Prep student enrollment/dosage file for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY Location (A) School (A).
EXECUTE.

MATCH FILES /FILE = FINALDATASET
   /TABLE = SchoolIDs
   /BY Location School.
DATASET NAME FINALDATASET.
EXECUTE.

***** Create a table for the output file in case we need to check and see if all school IDs merged okay.
FREQUENCIES VARIABLES = cyschSchoolRefID.

***** No longer need school ID data file.
DATASET CLOSE SchoolIDs.

************************************************************************************************************************************************************************************
***** Merge in cychannel school IDs.
************************************************************************************************************************************************************************************

***** Prep school ID file for merge.
DATASET ACTIVATE SchoolIDTranslation.
DELETE VARIABLES Location School School_A Location_A.
SORT CASES BY cyschSchoolRefID (A).
EXECUTE.

***** Prep student enrollment/dosage file for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cyschSchoolRefID (A).
EXECUTE.

MATCH FILES /FILE = FINALDATASET
   /TABLE = SchoolIDTranslation
   /BY cyschSchoolRefID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need school ID translation file.
DATASET CLOSE SchoolIDTranslation.

************************************************************************************************************************************************************************************
***** Merge in cychannel school info (mostly for Diplomas Now school variable).
************************************************************************************************************************************************************************************

***** Prep cychannel school IDs for merge.
DATASET ACTIVATE cychanSchoolInfo.
DELETE VARIABLES AccountID AccountName Subtype TotalPastPartnerships i3SchoolPartnership BillingStreet BillingCity BillingStateProvince BillingZipPostalCode
CityYearServiceLocation.
RENAME VARIABLES (Account = cychanSchoolID) (DiplomasNowSchoolPartnership = DNSchool).
VARIABLE LABELS DNSchool "Diplomas Now Schools".
VALUE LABELS DNSchool 0 "Not a Diplomas Now School"
   1 "Diplomas Now School".
SORT CASES BY cychanSchoolID (A).
EXECUTE.

***** Prep student enrollment/dosage file for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cychanSchoolID (A).
EXECUTE.

MATCH FILES /FILE = FINALDATASET
   /TABLE = cychanSchoolInfo
   /BY cychanSchoolID.
DATASET NAME FINALDATASET.
EXECUTE.

***** Create additional DN variable to account for variable DN status within a DN school. Only use this for filtering/calculation purposes. Use original variable to aggregate.
COMPUTE DN_SCHOOL_BY_GRADE = DNSchool.
EXECUTE.
IF (cyschSchoolRefID = "001U0000008x3NoIAI" & StudentGrade < 9) DN_SCHOOL_BY_GRADE = 0 /*CBS-Linden STEM*/ .
IF (cyschSchoolRefID = "001U000000O3C8PIAV" & StudentGrade < 9) DN_SCHOOL_BY_GRADE = 0 /*CBS-South HS*/ .
IF (cyschSchoolRefID = "001U000000EJ6m5IAD" & StudentGrade > 9) DN_SCHOOL_BY_GRADE = 0 /*JAX-Andrew Jackson High School*/ .
IF (cyschSchoolRefID = "001U000000YueJpIAJ") DN_SCHOOL_BY_GRADE = 0 /*TUL-Clinton MS*/ .
EXECUTE.
VARIABLE LABELS DN_SCHOOL_BY_GRADE "Diplomas Now Students (accounting for variation in school)".
VALUE LABELS DN_SCHOOL_BY_GRADE 0 "Not a Diplomas Now Student"
   1 "Diplomas Now Student".

***** No longer need cychannel school info file.
DATASET CLOSE cychanSchoolInfo.

************************************************************************************************************************************************************************************
***** Split RID Enrollment and Dosage Target Spreadsheet into Site and Team Versions.
************************************************************************************************************************************************************************************

***** Create copy of overall spreadsheet for team level file.
DATASET ACTIVATE SiteTeamEnrollDosage.
DATASET COPY TeamEnrollDosage.
DATASET ACTIVATE TeamEnrollDosage.
***** Delete rows with a blank value in cyschSchoolRefID.
SELECT IF (cyschSchoolRefID ~= "").
EXECUTE.

***** Create copy of overall spdreasheet for site level file.
DATASET ACTIVATE SiteTeamEnrollDosage.
DATASET COPY SiteEnrollDosage.
DATASET ACTIVATE SiteEnrollDosage.
***** Delete rows with a blank value in Location.
SELECT IF (Location ~= "").
EXECUTE.

***** Close original enrollment/dosage targets data file.
DATASET CLOSE SiteTeamEnrollDosage.

************************************************************************************************************************************************************************************
***** Merge in team-level goals.
************************************************************************************************************************************************************************************

***** Prep team-level enrollment and dosage goals for merge.
DATASET ACTIVATE TeamEnrollDosage.

RENAME VARIABLES (Location = TEAMLocation)	(SchoolName = TEAMSchoolName) (OpportunityName = TEAMOpportunityName) (IOGMinGrade = TEAMIOGMinGrade)
(IOGMaxGrade = TEAMIOGMaxGrade) (ELAEnrollGoal = TEAMELAEnrollGoal)	(MTHEnrollGoal = TEAMMTHEnrollGoal)	(ATTEnrollGoal = TEAMATTEnrollGoal)
(BEHEnrollGoal = TEAMBEHEnrollGoal) (Q2EnrollBench = TEAMQ2EnrollBench)	(Q3EnrollBench = TEAMQ3EnrollBench)	(ELAQ2DoseGoal = TEAMELAQ2DoseGoal)
(ELAQ3DoseGoal = TEAMELAQ3DoseGoal) (ELAQ4DoseGoal = TEAMELAQ4DoseGoal)	(MTHQ2DoseGoal = TEAMMTHQ2DoseGoal)
(MTHQ3DoseGoal = TEAMMTHQ3DoseGoal) (MTHQ4DoseGoal = TEAMMTHQ4DoseGoal) (Notes = TEAMNotes).

DELETE VARIABLES TEAMLocation TEAMOpportunityName TEAMNotes.

****************************************************************************************************
***** TEMP FIXES:.
*****     Editing enrollment goal data for Columbus Linden STEM Academy and South HS, and Jacksonville Andrew Jackson High School to ensure that
*****     enrollment goals show correctly for team-level goal table.
*****     This fix still allows separate dosage goals to be applied to lower vs. upper grades at these schools.
***** CBS-Linden STEM.
DO IF (cyschSchoolRefID = "001U0000008x3NoIAI").
COMPUTE TEAMELAEnrollGoal = 98.
COMPUTE TEAMMTHEnrollGoal = 98.
COMPUTE TEAMATTEnrollGoal = 99.
COMPUTE TEAMBEHEnrollGoal = 55.
COMPUTE TEAMQ2EnrollBench = 0.8 * 2 / 3.
COMPUTE TEAMQ3EnrollBench = 0.95.
END IF.
***** CBS-South HS.
DO IF (cyschSchoolRefID = "001U000000O3C8PIAV").
COMPUTE TEAMELAEnrollGoal = 160.
COMPUTE TEAMMTHEnrollGoal = 160.
COMPUTE TEAMATTEnrollGoal = 99.
COMPUTE TEAMBEHEnrollGoal = 66.
COMPUTE TEAMQ2EnrollBench = 0.8 * 2 / 3.
COMPUTE TEAMQ3EnrollBench = 0.95.
END IF.
EXECUTE.
***** JAX-Andrew Jackson High School.
DO IF (cyschSchoolRefID = "001U000000EJ6m5IAD").
COMPUTE TEAMELAEnrollGoal = 74.
COMPUTE TEAMMTHEnrollGoal = 37.
COMPUTE TEAMATTEnrollGoal = 54.
COMPUTE TEAMBEHEnrollGoal = 0.
COMPUTE TEAMQ2EnrollBench = 0.85.
COMPUTE TEAMQ3EnrollBench = 1.
END IF.
EXECUTE.
****************************************************************************************************

***** Add variable labels to existing variables.
VARIABLE LABELS TEAMELAEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 ELA/Literacy Focus List"
   TEAMMTHEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 Math Focus List"
   TEAMATTEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 Attendance Focus List"
   TEAMBEHEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 Behavior Focus List"
   TEAMELAQ2DoseGoal "DOSAGE GOAL (Q2)\nTeam-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ3DoseGoal "DOSAGE GOAL (Q3)\nTeam-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ4DoseGoal "DOSAGE GOAL (Q4)\nTeam-Level ELA/Literacy Per-Student (in hours)"
   TEAMMTHQ2DoseGoal "DOSAGE GOAL (Q2)\nTeam-Level Math Per-Student (in hours)"
   TEAMMTHQ3DoseGoal "DOSAGE GOAL (Q3)\nTeam-Level Math Per-Student (in hours)"
   TEAMMTHQ4DoseGoal "DOSAGE GOAL (Q4)\nTeam-Level Math Per-Student (in hours)".
EXECUTE.

***** Convert dosage goal columns into minutes for calculations.
COMPUTE TEAMELAQ2DoseGoalMin = TEAMELAQ2DoseGoal * 60.
COMPUTE TEAMELAQ3DoseGoalMin = TEAMELAQ3DoseGoal * 60.
COMPUTE TEAMELAQ4DoseGoalMin = TEAMELAQ4DoseGoal * 60.
COMPUTE TEAMMTHQ2DoseGoalMin = TEAMMTHQ2DoseGoal * 60.
COMPUTE TEAMMTHQ3DoseGoalMin = TEAMMTHQ3DoseGoal * 60.
COMPUTE TEAMMTHQ4DoseGoalMin = TEAMMTHQ4DoseGoal * 60.
VARIABLE LABELS    TEAMELAQ2DoseGoalMin "DOSAGE GOAL (Q2)\nTeam-Level ELA/Literacy Per-Student (in minutes)"
   TEAMELAQ3DoseGoalMin "DOSAGE GOAL (Q3)\nTeam-Level ELA/Literacy Per-Student (in minutes)"
   TEAMELAQ4DoseGoalMin "DOSAGE GOAL (Q4)\nTeam-Level ELA/Literacy Per-Student (in minutes)"
   TEAMMTHQ2DoseGoalMin "DOSAGE GOAL (Q2)\nTeam-Level Math Per-Student (in minutes)"
   TEAMMTHQ3DoseGoalMin "DOSAGE GOAL (Q3)\nTeam-Level Math Per-Student (in minutes)"
   TEAMMTHQ4DoseGoalMin "DOSAGE GOAL (Q4)\nTeam-Level Math Per-Student (in minutes)".
EXECUTE.

***** Compute indicator area-level Q2 and Q3 enrollment numeric benchmarks, based on percentage benchmarks.
*****     Q2.
COMPUTE TEAMELAQ2EnrollBench = RND(TEAMELAEnrollGoal * TEAMQ2EnrollBench).
COMPUTE TEAMMTHQ2EnrollBench = RND(TEAMMTHEnrollGoal * TEAMQ2EnrollBench).
COMPUTE TEAMATTQ2EnrollBench = RND(TEAMATTEnrollGoal * TEAMQ2EnrollBench).
COMPUTE TEAMBEHQ2EnrollBench = RND(TEAMBEHEnrollGoal * TEAMQ2EnrollBench).
*****     Q3.
COMPUTE TEAMELAQ3EnrollBench = RND(TEAMELAEnrollGoal * TEAMQ3EnrollBench).
COMPUTE TEAMMTHQ3EnrollBench = RND(TEAMMTHEnrollGoal * TEAMQ3EnrollBench).
COMPUTE TEAMATTQ3EnrollBench = RND(TEAMATTEnrollGoal * TEAMQ3EnrollBench).
COMPUTE TEAMBEHQ3EnrollBench = RND(TEAMBEHEnrollGoal * TEAMQ3EnrollBench).
VARIABLE LABELS TEAMELAQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level ELA/Literacy Enrollment"
   TEAMMTHQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level Math Enrollment"
   TEAMATTQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level Attendance Enrollment"
   TEAMBEHQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level Behavior Enrollment"
   TEAMELAQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level ELA/Literacy Enrollment"
   TEAMMTHQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level Math Enrollment"
   TEAMATTQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level Attendance Enrollment"
   TEAMBEHQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level Behavior Enrollment".
EXECUTE.

***** Compute final indicator area-level dosage benchmarks, based on the 80% threshold given by the LEAD measures.
COMPUTE TEAMELADoseBench = RND(TEAMELAEnrollGoal * 0.8).
COMPUTE TEAMMTHDoseBench = RND(TEAMMTHEnrollGoal * 0.8).
COMPUTE TEAMATTDoseBench = RND(TEAMATTEnrollGoal * 0.8).
COMPUTE TEAMBEHDoseBench = RND(TEAMBEHEnrollGoal * 0.8).
VARIABLE LABELS TEAMELADoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level ELA/Literacy Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMMTHDoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level Math Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMATTDoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level Attendance Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMBEHDoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level Behavior Focus List Dosage (80% of FL enrollment will meet dosage target)".
EXECUTE.

***** Need to reformat file so that the file is aggregated by school and grade level (because Linden STEM and South HS (Columbus), and Andrew Jackson High School
*****     (Jacksonville) have differing dosage goals by grade.
*****     grdtemp is the number of grade levels possible.
COMPUTE grdtemp = 14.
EXECUTE.
IF (TEAMSchoolName = "South High School - MS grades") grdtemp = 10.
IF (TEAMSchoolName = "South High School  DN- HS grades") grdtemp = 4.
IF (TEAMSchoolName = "Linden McKinley STEM Academy - MS Grades") grdtemp = 10.
IF (TEAMSchoolName = "Linden McKinley STEM Academy") grdtemp = 4.
IF (TEAMSchoolName = "Andrew Jackson High School - non-DN") grdtemp = 3.
IF (TEAMSchoolName = "Andrew Jackson High School - DN") grdtemp = 11.
EXECUTE.

LOOP id=1 TO 14. 
XSAVE OUTFILE='TeamEnrollDosageByGrade'
   /KEEP ALL. 
END LOOP. 
EXECUTE. 
GET FILE 'TeamEnrollDosageByGrade'. 
SELECT IF (id LE grdtemp). 
EXECUTE.
DATASET NAME TeamEnrollDosageByGrade.

***** Set initial grade value.
COMPUTE StudentGrade = -1.
EXECUTE.
IF (TEAMSchoolName = "South High School  DN- HS grades") StudentGrade = 9.
IF (TEAMSchoolName = "Linden McKinley STEM Academy") StudentGrade = 9.
IF (TEAMSchoolName = "Andrew Jackson High School - non-DN") StudentGrade = 10.
EXECUTE.
***** Sort by cyschSchoolRefID and Student Grade.
SORT CASES BY cyschSchoolRefID (A) StudentGrade (A).
EXECUTE.
***** Create student grade variable.
DO IF (cyschSchoolRefID = LAG(cyschSchoolRefID)).
COMPUTE StudentGrade = LAG(StudentGrade) + 1.
END IF.
EXECUTE.

***** Prep student enrollment and dosage dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cyschSchoolRefID (A) StudentGrade (A).
EXECUTE.

***** Merge in team-level enrollment and dosage goals to student enrollment and dosage dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = TeamEnrollDosageByGrade
   /BY cyschSchoolRefID StudentGrade.
DATASET NAME FINALDATASET.
ALTER TYPE StudentGrade (F2.0).
EXECUTE.

***** No longer need team enrollment dosage goal dataset.
DATASET CLOSE TeamEnrollDosage.

************************************************************************************************************************************************************************************
***** Merge in site-level goals.
************************************************************************************************************************************************************************************

***** Prep site-level enrollment and dosage goals for merge.
DATASET ACTIVATE SiteEnrollDosage.
ALTER TYPE Location (A14).
RECODE Location ("Washington DC" = "Washington, DC").
EXECUTE.

RENAME VARIABLES (cyschSchoolRefID = SITEcyschSchoolRefID)	(SchoolName = SITESchoolName) (OpportunityName = SITEOpportunityName)
(IOGMinGrade = SITEIOGMinGrade) (IOGMaxGrade = SITEIOGMaxGrade) (ELAEnrollGoal = SITEELAEnrollGoal)	(MTHEnrollGoal = SITEMTHEnrollGoal)
(ATTEnrollGoal = SITEATTEnrollGoal) (BEHEnrollGoal = SITEBEHEnrollGoal) (Q2EnrollBench = SITEQ2EnrollBench)	(Q3EnrollBench = SITEQ3EnrollBench)
(ELAQ2DoseGoal = SITEELAQ2DoseGoal) (ELAQ3DoseGoal = SITEELAQ3DoseGoal) (ELAQ4DoseGoal = SITEELAQ4DoseGoal)
(MTHQ2DoseGoal = SITEMTHQ2DoseGoal)	(MTHQ3DoseGoal = SITEMTHQ3DoseGoal) (MTHQ4DoseGoal = SITEMTHQ4DoseGoal) (Notes = SITENotes).

DELETE VARIABLES SITEcyschSchoolRefID SITESchoolName SITEOpportunityName SITEIOGMinGrade SITEIOGMaxGrade SITENotes.

****************************************************************************************************
***** TEMP FIXES:.
*****     Editing enrollment goal data for Columbus and Detroit, to ensure that enrollment goals show correctly for site-level goal table.
*****     This fix is necessary because of variation in goals across schools.
*****     Q2 percentages are approximate. Due to variation in quarterly enrollment goal percentages across schools, and since these percentages apply across all.
*****          indicator areas, there's no one percentage value that will accurately calculate total enrollment goal for all fields.
***** Columbus.
DO IF (Location = "Columbus").
COMPUTE SITEQ2EnrollBench = 0.57 /*approximate*/ .
COMPUTE SITEQ3EnrollBench = 0.95.
END IF.
***** Detroit.
DO IF (Location = "Detroit").
COMPUTE SITEQ2EnrollBench = 0.76 /*approximate*/ .
COMPUTE SITEQ3EnrollBench = 0.95.
END IF.
EXECUTE.
****************************************************************************************************

***** Add variable labels to existing variables.
VARIABLE LABELS SITEELAEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 ELA/Literacy Focus List"
   SITEMTHEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 Math Focus List"
   SITEATTEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 Attendance Focus List"
   SITEBEHEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 Behavior Focus List"
   SITEELAQ2DoseGoal "DOSAGE GOAL (Q2)\nSite-Level ELA/Literacy Average Per-Student (in hours)"
   SITEELAQ3DoseGoal "DOSAGE GOAL (Q3)\nSite-Level ELA/Literacy Average Per-Student (in hours)"
   SITEELAQ4DoseGoal "DOSAGE GOAL (Q4)\nSite-Level ELA/Literacy Average Per-Student (in hours)"
   SITEMTHQ2DoseGoal "DOSAGE GOAL (Q2)\nSite-Level Math Average Per-Student (in hours)"
   SITEMTHQ3DoseGoal "DOSAGE GOAL (Q3)\nSite-Level Math Average Per-Student (in hours)"
   SITEMTHQ4DoseGoal "DOSAGE GOAL (Q4)\nSite-Level Math Average Per-Student (in hours)".
EXECUTE.

***** Convert dosage goal columns into minutes for calculations.
COMPUTE SITEELAQ2DoseGoalMin = SITEELAQ2DoseGoal * 60.
COMPUTE SITEELAQ3DoseGoalMin = SITEELAQ3DoseGoal * 60.
COMPUTE SITEELAQ4DoseGoalMin = SITEELAQ4DoseGoal * 60.
COMPUTE SITEMTHQ2DoseGoalMin = SITEMTHQ2DoseGoal * 60.
COMPUTE SITEMTHQ3DoseGoalMin = SITEMTHQ3DoseGoal * 60.
COMPUTE SITEMTHQ4DoseGoalMin = SITEMTHQ4DoseGoal * 60.
VARIABLE LABELS SITEELAQ2DoseGoalMin "DOSAGE GOAL (Q2)\nSite-Level ELA/Literacy Average Per-Student (in minutes)"
   SITEELAQ3DoseGoalMin "DOSAGE GOAL (Q3)\nSite-Level ELA/Literacy Average Per-Student (in minutes)"
   SITEELAQ4DoseGoalMin "DOSAGE GOAL (Q4)\nSite-Level ELA/Literacy Average Per-Student (in minutes)"
   SITEMTHQ2DoseGoalMin "DOSAGE GOAL (Q2)\nSite-Level Math Average Per-Student (in minutes)"
   SITEMTHQ3DoseGoalMin "DOSAGE GOAL (Q3)\nSite-Level Math Average Per-Student (in minutes)"
   SITEMTHQ4DoseGoalMin "DOSAGE GOAL (Q4)\nSite-Level Math Average Per-Student (in minutes)".
EXECUTE.

***** Compute indicator area-level Q2 and Q3 enrollment numeric benchmarks, based on percentage benchmarks.
*****     Q2.
COMPUTE SITEELAQ2EnrollBench = RND(SITEELAEnrollGoal * SITEQ2EnrollBench).
COMPUTE SITEMTHQ2EnrollBench = RND(SITEMTHEnrollGoal * SITEQ2EnrollBench).
COMPUTE SITEATTQ2EnrollBench = RND(SITEATTEnrollGoal * SITEQ2EnrollBench).
COMPUTE SITEBEHQ2EnrollBench = RND(SITEBEHEnrollGoal * SITEQ2EnrollBench).
*****     Q3.
COMPUTE SITEELAQ3EnrollBench = RND(SITEELAEnrollGoal * SITEQ3EnrollBench).
COMPUTE SITEMTHQ3EnrollBench = RND(SITEMTHEnrollGoal * SITEQ3EnrollBench).
COMPUTE SITEATTQ3EnrollBench = RND(SITEATTEnrollGoal * SITEQ3EnrollBench).
COMPUTE SITEBEHQ3EnrollBench = RND(SITEBEHEnrollGoal * SITEQ3EnrollBench).
VARIABLE LABELS SITEELAQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level ELA/Literacy Enrollment"
   SITEMTHQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level Math Enrollment"
   SITEATTQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level Attendance Enrollment"
   SITEBEHQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level Behavior Enrollment"
   SITEELAQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level ELA/Literacy Enrollment"
   SITEMTHQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level Math Enrollment"
   SITEATTQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level Attendance Enrollment"
   SITEBEHQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level Behavior Enrollment".
EXECUTE.

SORT CASES BY Location (A).

***** Prep student enrollment and dosage dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY Location (A).

***** Merge site-level enrollment and dosage goals to student enrollment and dosage dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = SiteEnrollDosage
   /BY Location.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need site enrollment dosage goal dataset.
DATASET CLOSE SiteEnrollDosage.

************************************************************************************************************************************************************************************
***** Merge in AC Grant IDs.
************************************************************************************************************************************************************************************

***** Prep grant IDs data file for merge.
DATASET ACTIVATE ACGrantIDs.
***** Delete unnecessary variables.
DELETE VARIABLES Location School GrantSite.
***** Add value labels for existing variables.
VALUE LABELS GrantCategory 1 "National Direct"
   2 "State Commission"
   3 "School Turnaround AmeriCorps".
VALUE LABELS GrantSiteNum 1 "Boston [ND]"
2 "Columbus [ND]"
3 "Denver [ND]"
4 "Jacksonville [ND]"
5 "Little Rock [ND]"
6 "Los Angeles [ND]"
7 "Miami [ND]"
8 "Milwaukee [ND]"
9 "Rhode Island [ND]"
10 "Sacramento [ND]"
11 "San Jose [ND]"
12 "Seattle [ND]"
13 "Tulsa [ND]"
14 "Washington, DC [ND]"
15 "Boston [State]"
16 "Chicago [State]"
17 "Cleveland [State]"
18 "Columbia [State]"
19 "Columbus [State]"
20 "Detroit [State]"
21 "Los Angeles [State]"
22 "Louisiana (Baton Rouge) [State]"
23 "Louisiana (New Orleans) [State]"
24 "Miami [State Competitive]"
25 "Miami [State Formula]"
26 "New Hampshire [State]"
27 "New York (DN) [State]"
28 "New York [State]"
29 "Orlando [State GMI]"
30 "Orlando [State]"
31 "Philadelphia [State]"
32 "San Antonio [State]"
33 "Washington, DC [State]"
34 "Chicago / Kelvyn Park High School [STA]"
35 "Chicago / Tilden Career Community Academy HS [STA]"
36 "Denver / North High School [STA]"
37 "Denver / Trevista at Horace Mann [STA]"
38 "Los Angeles / Clinton MS [STA]"
39 "Washington, DC / DC Scholars Stanton Elementary School [STA]".
EXECUTE.
VARIABLE LABELS GrantCategory "Grant Category"
   GrantSiteNum "Grant / Site".
EXECUTE.
SORT CASES BY cyschSchoolRefID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cyschSchoolRefID (A).
EXECUTE.

***** Merge AC grant IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE ACGrantIDs
   /BY cyschSchoolRefID.
DATASET NAME FINALDATASET.
EXECUTE.

************************************************************************************************************************************************************************************
***** Merge in AC Grant-Level Information.
************************************************************************************************************************************************************************************

***** Prep AC goals file for merge.
DATASET ACTIVATE ACGoals.
***** Delete unnecessary variables.
DELETE VARIABLES DELETE1 DELETE2 DELETE3 DELETE4 DELETE5 DELETE6 DELETE7 DELETE8 DELETE9 DELETE10 DELETE11 DELETE12 DELETE13
DELETE14 DELETE15 DELETE16 DELETE17 DELETE18 DELETE19 DELETE20 DELETE21 DELETE22 DELETE23 DELETE24 DELETE25 DELETE26 DELETE27
DELETE28 DELETE29 DELETE30 DELETE31 DELETE32 DELETE33 DELETE34 DELETE35 DELETE36 DELETE37 DELETE38 DELETE39 DELETE40 DELETE41
DELETE42 DELETE43 DELETE44 DELETE45 DELETE46 DELETE47 DELETE48 DELETE49 DELETE50 DELETE51 DELETE52 DELETE53 DELETE54 DELETE55
DELETE56 DELETE57 DELETE58 DELETE59 DELETE60 DELETE61 DELETE62.
***** Rename linking ID variable.
RENAME VARIABLES (EVAL_ID = GrantSiteNum).
***** Add value labels for existing variables.
VALUE LABELS ACreportLIT 0 "Not reporting on literacy for AmeriCorps"
   1 "Reporting on literacy for AmeriCorps".
VALUE LABELS ACreportMTH 0 "Not reporting on math for AmeriCorps"
   1 "Reporting on math for AmeriCorps".
VALUE LABELS ACreportATT 0 "Not reporting on attendance for AmeriCorps"
   1 "Reporting on attendance for AmeriCorps".
VALUE LABELS ACreportBEH 0 "Not reporting on behavior for AmeriCorps"
   1 "Reporting on behavior for AmeriCorps".
EXECUTE.
***** Add variable labels for existing variables.
VARIABLE LABELS ACreportLIT "Reporting on literacy for AmeriCorps? [0=No; 1=Yes]"
   ACreportMTH "Reporting on math for AmeriCorps? [0=No; 1=Yes]"
   ACreportATT "Reporting on attendance for AmeriCorps? [0=No; 1=Yes]"
   ACreportBEH "Reporting on behavior for AmeriCorps? [0=No; 1=Yes]"
   ACED1AcadGoal "GOAL ED1 Academic:\nUnique Number of Students Enrolled in Literacy or Math"
   ACED2AcadGoal "GOAL ED2 Academic:\nUnique Number of Students Who Met Dosage in Literacy or Math"
   ACED5AcadGoal "GOAL ED5 Academic:\nUnique Number of Students Who Met Performance Goal in Literacy or Math"
   ACED1StEngGoal "GOAL ED1 Student Engagement:\nUnique Number of Students Enrolled in Attendance or Behavior"
   ACED2StEngGoal "GOAL ED2 Student Engagement:\nUnique Number of Students Who Met Dosage in Attendance or Behavior"
   ACED27StEngGoal "GOAL ED27 Student Engagement:\nUnique Number of Students Who Met Performance Goal in Attendance or Behavior".
EXECUTE.
SORT CASES BY GrantSiteNum (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY GrantSiteNum (A).
EXECUTE.

***** Merge AC goals to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = ACGoals
   /BY GrantSiteNum.
DATASET NAME FINALDATASET.
EXECUTE.

****************************************************************************************************
***** REPORTING EXCEPTION:.
*****     North High School in Denver is not reporting on math -- see email chain forwarded by Ashley on 12/17/2013 "Fwd: Follow up re: math at North".
IF (cyschSchoolRefID = "001U0000008x3MwIAI") ACreportMTH = 0.
EXECUTE.
****************************************************************************************************

***** No longer need AC data files.
DATASET CLOSE ACGrantIDs.
DATASET CLOSE ACGoals.

************************************************************************************************************************************************************************************
***** Merge in student performance ID translation file.
************************************************************************************************************************************************************************************

***** Prep student ID translation file for merge.
DATASET ACTIVATE StPerfIDs.
***** Delete unnecessary variables.
DELETE VARIABLES FIRST_NAME MIDDLE_NAME LAST_NAME REGION_ID REGION_NAME SITE_NAME CYCHANNEL_SCHOOL_ACCOUNT_NBR
SCHOOL_NAME DIPLOMAS_NOW_SCHOOL GENDER GRADE_ID GRADE_DESC PRIMARY_CM_ID PRIMARY_CM_NAME CYCHANNEL_ACCOUNT_NBR
Attendance_IA ELA_IA Math_IA Behavior_IA.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (CYSCHOOLHOUSE_STUDENT_ID = cyStudentID) (SITE_ID = cysdSiteID) (SCHOOL_ID = cysdSchoolID).
***** Add variable labels for existing variables.
VARIABLE LABELS cysdStudentID "cystudentdata: Student ID"
   cysdSiteID "cystudentdata: Site ID"
   cysdSchoolID "cystudentdata: School ID".
EXECUTE.
ALTER TYPE cysdStudentID cysdSiteID cysdSchoolID (F40.0).
SORT CASES BY cyStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cyStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = StPerfIDs
   /BY cyStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** Some records don't have a linked cystudentdata ID. This appears to be because a couple records from FY13 are pulling into cyschoolhouse export.
***** Select only records with a linked cystudentdata ID (i.e. FY14 records).
SELECT IF NOT MISSING(cysdStudentID).
EXECUTE.

***** No longer need the student ID translation file.
DATASET CLOSE StPerfIDs.

************************************************************************************************************************************************************************************
***** Merge in literacy assessment performance data.
************************************************************************************************************************************************************************************

***** Prep literacy assessment data file for merge.
DATASET ACTIVATE LITAssessPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID ASSESSMENT_TYPE PRE_VALUE
PRE_TRACK_NATIONAL POST_VALUE POST_TRACK_NATIONAL DOSAGE_CATEGORY TTL_TIME ENROLLED_DAYS_CATEGORIES CURRENTLY_ENROLLED
ENROLLED_DAYS LIT_ASSESS_RAWCHANGE LIT_ASSESS_PERCENTCHANGE STATUS_SITE_DOSAGE_GOAL SITE_DOSAGE_GOAL Attendance_IA
ELA_IA Math_IA Behavior_IA INDICATOR_ID B_RULE_VAL1 B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4 B_RULE_VAL5 GRADE_ID_RECODE
EOY_MET_Q3_DOSAGE DN_SCHOOL_BY_GRADE EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_VALUE_DISPLAY = LITAssess_PRE_VALUE_DISPLAY)
(PRE_VALUE_NUM = LITAssess_PRE_VALUE_NUM) (PRE_DATE = LITAssess_PRE_DATE) (PRE_DESC = LITAssess_PRE_DESC)
(PRE_TRACK = LITAssess_PRE_TRACK) (PRE_TRACK_EVAL = LITAssess_PRE_TRACK_EVAL) (POST_VALUE_DISPLAY = LITAssess_POST_VALUE_DISPLAY)
(POST_VALUE_NUM = LITAssess_POST_VALUE_NUM) (POST_DATE = LITAssess_POST_DATE) (POST_DESC = LITAssess_POST_DESC)
(POST_TRACK = LITAssess_POST_TRACK) (POST_TRACK_EVAL = LITAssess_POST_TRACK_EVAL)
(LIT_ASSESS_RAWCHANGE_DEGREE = LITAssess_RAWCHANGE_DEG) (LIT_ASSESS_PERFORMANCECHANGE_LOCAL = LITAssess_PERFCHANGE_LOCAL)
(LIT_ASSESS_PERFORMANCECHANGE_NORMALIZED = LITAssess_PERFCHANGE_NORM).
***** Add variable labels for existing variables.
VARIABLE LABELS LITAssess_PRE_VALUE_DISPLAY "Literacy Assessments: pre raw score (display)"
LITAssess_PRE_VALUE_NUM "Literacy Assessments: pre raw score (numeric)"
LITAssess_PRE_DATE "Literacy Assessments: pre date"
LITAssess_PRE_DESC "Literacy Assessments: pre assessment type"
LITAssess_PRE_TRACK "Literacy Assessments: pre performance level"
LITAssess_PRE_TRACK_EVAL "Literacy Assessments: pre performance level (normalized)"
LITAssess_POST_VALUE_DISPLAY "Literacy Assessments: post raw score (display)"
LITAssess_POST_VALUE_NUM "Literacy Assessments: post raw score (numeric)"
LITAssess_POST_DATE "Literacy Assessments: post date"
LITAssess_POST_DESC "Literacy Assessments: post assessment type"
LITAssess_POST_TRACK "Literacy Assessments: post performance level"
LITAssess_POST_TRACK_EVAL "Literacy Assessments: post performance level (normalized)"
LITAssess_RAWCHANGE_DEG "Literacy Assessments: pre to post raw score change (degree)"
LITAssess_PERFCHANGE_LOCAL "Literacy Assessments: pre to post change in performance level"
LITAssess_PERFCHANGE_NORM "Literacy Assessments: pre to post change in performance level (normalized)".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = LITAssessPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the literacy assessment dataset.
DATASET CLOSE LITAssessPerf.

************************************************************************************************************************************************************************************
***** Merge in math assessment performance data.
************************************************************************************************************************************************************************************

***** Prep math assessment data file for merge.
DATASET ACTIVATE MTHAssessPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID ASSESSMENT_TYPE PRE_VALUE
PRE_TRACK_NATIONAL POST_VALUE POST_TRACK_NATIONAL DOSAGE_CATEGORY TTL_TIME ENROLLED_DAYS_CATEGORIES
CURRENTLY_ENROLLED ENROLLED_DAYS LIT_ASSESS_RAWCHANGE LIT_ASSESS_PERCENTCHANGE STATUS_SITE_DOSAGE_GOAL
SITE_DOSAGE_GOAL Attendance_IA ELA_IA Math_IA Behavior_IA INDICATOR_ID B_RULE_VAL1 B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4
B_RULE_VAL5 GRADE_ID_RECODE EOY_MET_Q3_DOSAGE DN_SCHOOL_BY_GRADE EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_VALUE_DISPLAY = MTHAssess_PRE_VALUE_DISPLAY)
(PRE_VALUE_NUM = MTHAssess_PRE_VALUE_NUM) (PRE_DATE = MTHAssess_PRE_DATE) (PRE_DESC = MTHAssess_PRE_DESC)
(PRE_TRACK = MTHAssess_PRE_TRACK) (PRE_TRACK_EVAL = MTHAssess_PRE_TRACK_EVAL)
(POST_VALUE_DISPLAY = MTHAssess_POST_VALUE_DISPLAY) (POST_VALUE_NUM = MTHAssess_POST_VALUE_NUM)
(POST_DATE = MTHAssess_POST_DATE) (POST_DESC = MTHAssess_POST_DESC) (POST_TRACK = MTHAssess_POST_TRACK)
(POST_TRACK_EVAL = MTHAssess_POST_TRACK_EVAL) (LIT_ASSESS_RAWCHANGE_DEGREE = MTHAssess_RAWCHANGE_DEG)
(LIT_ASSESS_PERFORMANCECHANGE_LOCAL = MTHAssess_PERFCHANGE_LOCAL)
(LIT_ASSESS_PERFORMANCECHANGE_NORMALIZED = MTHAssess_PERFCHANGE_NORM).
***** Add variable labels for existing variables.
VARIABLE LABELS MTHAssess_PRE_VALUE_DISPLAY "Math Assessments: pre raw score (display)"
MTHAssess_PRE_VALUE_NUM "Math Assessments: pre raw score (numeric)"
MTHAssess_PRE_DATE "Math Assessments: pre date"
MTHAssess_PRE_DESC "Math Assessments: pre assessment type"
MTHAssess_PRE_TRACK "Math Assessments: pre performance level (local)"
MTHAssess_PRE_TRACK_EVAL "Math Assessments: pre performance level (normalized)"
MTHAssess_POST_VALUE_DISPLAY "Math Assessments: post raw score (display)"
MTHAssess_POST_VALUE_NUM "Math Assessments: post raw score (numeric)"
MTHAssess_POST_DATE "Math Assessments: post date"
MTHAssess_POST_DESC "Math Assessments: post assessment type"
MTHAssess_POST_TRACK "Math Assessments: post performance level (local)"
MTHAssess_POST_TRACK_EVAL "Math Assessments: post performance level (normalized)"
MTHAssess_RAWCHANGE_DEG "Math Assessments: pre to post change in raw score (degree)"
MTHAssess_PERFCHANGE_LOCAL "Math Assessments: pre to post change in performance level (local)"
MTHAssess_PERFCHANGE_NORM "Math Assessments: pre to post change in performance level (normalized)".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = MTHAssessPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the math assessment dataset.
DATASET CLOSE MTHAssessPerf.

************************************************************************************************************************************************************************************
***** Merge in ELA CG performance data.
************************************************************************************************************************************************************************************

***** Prep ELA course grade data file for merge.
DATASET ACTIVATE ELACGPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID PRE_ELA_CG_VALUE PRE_ELA_DESC
PRE_ELA_TRACK_EVAL PRE_SCENARIO DOSAGE_CATEGORY TTL_TIME POST_ELA_CG_VALUE POST_ELA_DESC POST_ELA_TRACK_EVAL
POST_SCENARIO CG_Change Enrollment_Duration ENROLL_DAYS STATUS_SITE_DOSAGE_GOAL SITE_DOSAGE_GOAL Attendance_IA ELA_IA
Math_IA Behavior_IA INDICATOR_ID B_RULE_VAL1 B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4 B_RULE_VAL5 GRADE_ID_RECODE
EOY_MET_Q3_DOSAGE DN_SCHOOL_BY_GRADE EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_ELA_CG_VALUE_DISPLAY = ELACG_PRE_VALUE_DISPLAY)
(PRE_ELA_CG_VALUE_NUM = ELACG_PRE_VALUE_NUM) (PRE_ELA_FREQ = ELACG_PRE_FREQ) (PRE_ELA_TRACK = ELACG_PRE_TRACK)
(PRE_LETTER_VIEW = ELACG_PRE_LETTER_VIEW) (PRE_CG_LETTER_SCALE_ALL = ELACG_PRE_LETTER_SCALE_ALL)
(POST_ELA_CG_VALUE_DISPLAY = ELACG_POST_VALUE_DISPLAY) (POST_ELA_CG_VALUE_NUM = ELACG_POST_VALUE_NUM)
(POST_ELA_FREQ = ELACG_POST_FREQ) (POST_ELA_TRACK = ELACG_POST_TRACK) (POST_LETTER_VIEW = ELACG_POST_LETTER_VIEW)
(POST_CG_LETTER_SCALE_ALL = ELACG_POST_LETTER_SCALE_ALL) (LETTERGADE_CHANGE_ACTUAL = ELACG_LTRGRD_CHANGE_ACTUAL)
(LETTERGADE_CHANGE_GENERAL = ELACG_LTRGRD_CHANGE_GENERAL) (CG_Performance_Level_Change = ELACG_PERF_LVL_CHANGE).
***** Add variable labels for existing variables.
VARIABLE LABELS ELACG_PRE_VALUE_DISPLAY "ELA Course Grades: pre course grade display"
ELACG_PRE_VALUE_NUM "ELA Course Grades: pre course grade (numeric)"
ELACG_PRE_FREQ "ELA Course Grades: pre time period"
ELACG_PRE_TRACK "ELA Course Grades: pre performance level"
ELACG_PRE_LETTER_VIEW "ELA Course Grades: pre letter grade"
ELACG_PRE_LETTER_SCALE_ALL "ELA Course Grades: pre letter scale"
ELACG_POST_VALUE_DISPLAY "ELA Course Grades: post course grade display"
ELACG_POST_VALUE_NUM "ELA Course Grades: post course grade (numeric)"
ELACG_POST_FREQ "ELA Course Grades: post time period"
ELACG_POST_TRACK "ELA Course Grades: post performance level"
ELACG_POST_LETTER_VIEW "ELA Course Grades: post letter grade"
ELACG_POST_LETTER_SCALE_ALL "ELA Course Grades: post letter scale"
ELACG_LTRGRD_CHANGE_ACTUAL "ELA Course Grades: pre to post change in letter grade"
ELACG_LTRGRD_CHANGE_GENERAL "ELA Course Grades: pre to post change in letter grade (degree)"
ELACG_PERF_LVL_CHANGE "ELA Course Grades: pre to post change in performance level".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = ELACGPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need ELA course grade dataset.
DATASET CLOSE ELACGPerf.

************************************************************************************************************************************************************************************
***** Merge in math CG performance data.
************************************************************************************************************************************************************************************

***** Prep math course grade data file for merge.
DATASET ACTIVATE MTHCGPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID PRE_MATH_CG_VALUE PRE_MATH_DESC
PRE_MATH_TRACK_EVAL PRE_SCENARIO POST_MATH_CG_VALUE POST_MATH_DESC POST_MATH_TRACK_EVAL POST_SCENARIO
DOSAGE_CATEGORY TTL_TIME CG_Change Enrollment_Duration ENROLL_DAYS STATUS_SITE_DOSAGE_GOAL SITE_DOSAGE_GOAL
Attendance_IA ELA_IA Math_IA Behavior_IA INDICATOR_ID B_RULE_VAL1 B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4 B_RULE_VAL5
GRADE_ID_RECODE EOY_MET_Q3_DOSAGE DN_SCHOOL_BY_GRADE EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_MATH_CG_VALUE_DISPLAY = MTHCG_PRE_VALUE_DISPLAY)
(PRE_MATH_CG_VALUE_NUM = MTHCG_PRE_VALUE_NUM) (PRE_MATH_FREQ = MTHCG_PRE_FREQ)
(PRE_MATH_TRACK = MTHCG_PRE_TRACK) (PRE_LETTER_VIEW = MTHCG_PRE_LETTER_VIEW)
(PRE_CG_LETTER_SCALE_ALL = MTHCG_PRE_LETTER_SCALE_ALL) (POST_MATH_CG_VALUE_DISPLAY = MTHCG_POST_VALUE_DISPLAY)
(POST_MATH_CG_VALUE_NUM = MTHCG_POST_VALUE_NUM) (POST_MATH_FREQ = MTHCG_POST_FREQ)
(POST_MATH_TRACK = MTHCG_POST_TRACK) (POST_LETTER_VIEW = MTHCG_POST_LETTER_VIEW)
(POST_CG_LETTER_SCALE_ALL = MTHCG_POST_LETTER_SCALE_ALL) (LETTERGADE_CHANGE_ACTUAL = MTHCG_LTRGRD_CHANGE_ACTUAL)
(LETTERGADE_CHANGE_GENERAL = MTHCG_LTRGRD_CHANGE_GENERAL) (CG_Performance_Level_Change = MTHCG_PERF_LVL_CHANGE).
***** Add variable labels for existing variables.
VARIABLE LABELS MTHCG_PRE_VALUE_DISPLAY "Math Course Grades: pre course grade display"
MTHCG_PRE_VALUE_NUM "Math Course Grades: pre course grade (numeric)"
MTHCG_PRE_FREQ "Math Course Grades: pre time period"
MTHCG_PRE_TRACK "Math Course Grades: pre performance level"
MTHCG_PRE_LETTER_VIEW "Math Course Grades: pre letter grade"
MTHCG_PRE_LETTER_SCALE_ALL "Math Course Grades: pre letter scale"
MTHCG_POST_VALUE_DISPLAY "Math Course Grades: post course grade display"
MTHCG_POST_VALUE_NUM "Math Course Grades: post course grade (numeric)"
MTHCG_POST_FREQ "Math Course Grades: post time period"
MTHCG_POST_TRACK "Math Course Grades: post performance level"
MTHCG_POST_LETTER_VIEW "Math Course Grades: post letter grade"
MTHCG_POST_LETTER_SCALE_ALL "Math Course Grades: post letter scale"
MTHCG_LTRGRD_CHANGE_ACTUAL "Math Course Grades: pre to post change in letter grade"
MTHCG_LTRGRD_CHANGE_GENERAL "Math Course Grades: pre to post change in letter grade (degree)"
MTHCG_PERF_LVL_CHANGE "Math Course Grades: pre to post change in performance level".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = MTHCGPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the math course grade dataset.
DATASET CLOSE MTHCGPerf.

************************************************************************************************************************************************************************************
***** Merge in attendance performance data.
************************************************************************************************************************************************************************************

***** Prep attendance performance data file for merge.
DATASET ACTIVATE ATTPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID PRE_SKILL_DESC PRE_SCENARIO
PRE_ATT_TRACK_EVAL PRE_INVALID_ADA POST_SKILL_DESC POST_SCENARIO POST_ATT_TRACK_EVAL POST_INVALID_ADA DOSAGE_CATEGORY
TTL_TIME ENROLLED_DAYS_CATEGORIES CURRENTLY_ENROLLED ENROLLED_DAYS ATT_PERFORMANCE_CHANGE_NATIONAL
ATT_ADA_CHANGE_TYPE Attendance_IA ELA_IA Math_IA Behavior_IA INDICATOR_ID B_RULE_VAL1 B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4
B_RULE_VAL5 GRADE_ID_RECODE EOY_MET_56_DAYS DN_SCHOOL_BY_GRADE EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_FREQ_DESC = ATT_PRE_FREQ_DESC) (PRE_ATT_ADA = ATT_PRE_ADA)
(PRE_ATT_SCHOOL_OPEN = ATT_PRE_SCHOOL_OPEN) (PRE_ATT_MISSING = ATT_PRE_MISSING) (PRE_ATT_NOT_ENROLLED = ATT_PRE_NOT_ENROLLED)
(PRE_ATT_TRACK = ATT_PRE_TRACK) (POST_FREQ_DESC = ATT_POST_FREQ_DESC) (POST_ATT_ADA = ATT_POST_ADA)
(POST_ATT_SCHOOL_OPEN = ATT_POST_SCHOOL_OPEN) (POST_ATT_MISSING = ATT_POST_MISSING)
(POST_ATT_NOT_ENROLLED = ATT_POST_NOT_ENROLLED) (POST_ATT_TRACK = ATT_POST_TRACK) (ATT_ADA_CHANGE = ATT_ADA_CHANGE)
(EOY_ATT_ADA_CHANGE_TYPE = ATT_ADA_CHANGE_TYPE) (EOY_ATT_INC_BY_2_PERC_PT = ATT_INC_BY_2_PERC_PT)
(ATT_PERFORMANCE_CHANGE_LOCAL = ATT_PERF_CHANGE_LOCAL) (IOG_LT_90_TO_GTE = ATT_IOG_LT_90_TO_GTE).
***** Add value labels for existing variables.
VALUE LABELS ATT_INC_BY_2_PERC_PT 0 "Did not increase ADA by at least 2 percentage points"
   1 "Increased ADA by at least 2 percentage points".
EXECUTE.
***** Add variable labels for existing variables.
VARIABLE LABELS ATT_PRE_FREQ_DESC "Attendance: pre time period"
ATT_PRE_ADA "Attendance: pre average daily attendance"
ATT_PRE_SCHOOL_OPEN "Attendance: pre number of days school open"
ATT_PRE_MISSING "Attendance: pre number of days missed"
ATT_PRE_NOT_ENROLLED "Attendance: pre number of days not enrolled"
ATT_PRE_TRACK "Attendance: pre performance level"
ATT_POST_FREQ_DESC "Attendance: post time period"
ATT_POST_ADA "Attendance: post average daily attendance"
ATT_POST_SCHOOL_OPEN "Attendance: post number of days school open"
ATT_POST_MISSING "Attendance: post number of days missed"
ATT_POST_NOT_ENROLLED "Attendance: post number of days not enrolled"
ATT_POST_TRACK "Attendance: post performance level"
ATT_ADA_CHANGE "Attendance: pre to post change in average daily attendance"
ATT_ADA_CHANGE_TYPE "Attendance: pre to post change in average daily attendance (degree)"
ATT_INC_BY_2_PERC_PT "Attendance: pre to post increase in ADA by at least 2 percentage points?"
ATT_PERF_CHANGE_LOCAL "Attendance: pre to post change in performance level"
ATT_IOG_LT_90_TO_GTE "Attendance: did the student start with <90% ADA and move to >=90% ADA?".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = ATTPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the attendance dataset.
DATASET CLOSE ATTPerf.

************************************************************************************************************************************************************************************
***** Merge in behavior rubric data.
************************************************************************************************************************************************************************************

***** Prep attendance performance data file for merge.
DATASET ACTIVATE BEHRUBPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID CURRENTLY_ENROLLED ENROLLED_DAYS
ENROLLED_DAYS_CATEGORIES TTL_TIME DOSAGE_CATEGORIES Attendance_IA ELA_IA Math_IA Behavior_IA INDICATOR_ID B_RULE_VAL1
B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4 B_RULE_VAL5 GRADE_ID_RECODE EOY_MET_56_DAYS DN_SCHOOL_BY_GRADE
EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_INTERVAL = BEHRUB_PRE_INTERVAL)
(PRE_SLF_AWR_PERF_VALUE = BEHRUB_PRE_SLF_AWR) (PRE_SLF_MNG_PERF_VALUE = BEHRUB_PRE_SLF_MNG)
(PRE_SCL_AWR_PERF_VALUE = BEHRUB_PRE_SCL_AWR) (PRE_REL_SKL_PERF_VALUE = BEHRUB_PRE_REL_SKL)
(PRE_RES_DCN_MAK_PERF_VALUE = BEHRUB_PRE_RES_DCN_MAK) (AVG_PRE_SCORE = BEHRUB_PRE_SCORE_AVG)
(POST_INTERVAL = BEHRUB_POST_INTERVAL) (POST_SLF_AWR_PERF_VALUE = BEHRUB_POST_SLF_AWR)
(POST_SLF_MNG_PERF_VALUE = BEHRUB_POST_SLF_MNG) (POST_SCL_AWR_PERF_VALUE = BEHRUB_POST_SCL_AWR)
(POST_REL_SKL_PERF_VALUE = BEHRUB_POST_REL_SKL) (POST_RES_DCN_MAK_PERF_VALUE = BEHRUB_POST_RES_DCN_MAK)
(AVG_POST_SCORE = BEHRUB_POST_SCORE_AVG) (AVG_CHANGE_PRE_TO_POST = BEHRUB_CHANGE_AVG).
***** Add variable labels for existing variables.
VARIABLE LABELS BEHRUB_PRE_INTERVAL "Behavior Rubric: pre date"
BEHRUB_PRE_SLF_AWR "Behavior Rubric: pre skill: self awareness"
BEHRUB_PRE_SLF_MNG "Behavior Rubric: pre skill: self management"
BEHRUB_PRE_SCL_AWR "Behavior Rubric: pre skill: social awareness"
BEHRUB_PRE_REL_SKL "Behavior Rubric: pre skill: relationship skills"
BEHRUB_PRE_RES_DCN_MAK "Behavior Rubric: pre skill: responsible decision making"
BEHRUB_PRE_SCORE_AVG "Behavior Rubric: pre average score"
BEHRUB_POST_INTERVAL "Behavior Rubric: post date"
BEHRUB_POST_SLF_AWR "Behavior Rubric: post skill: self awareness"
BEHRUB_POST_SLF_MNG "Behavior Rubric: post skill: self management"
BEHRUB_POST_SCL_AWR "Behavior Rubric: post skill: social awareness"
BEHRUB_POST_REL_SKL "Behavior Rubric: post skill: relationship skills"
BEHRUB_POST_RES_DCN_MAK "Behavior Rubric: post skill: responsible decision making"
BEHRUB_POST_SCORE_AVG "Behavior Rubric: post average score"
BEHRUB_CHANGE_AVG "Behavior Rubric: pre to post change in average score".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = BEHRUBPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the attendance dataset.
DATASET CLOSE BEHRUBPerf.

************************************************************************************************************************************************************************************
***** Merge in school-based behavior data.
************************************************************************************************************************************************************************************

***** Prep attendance performance data file for merge.
DATASET ACTIVATE BEHSCHPerf.
***** Delete unnecessary variables.
DELETE VARIABLES SITE_NAME SCHOOL_NAME GRADE_ID DIPLOMAS_NOW_SCHOOL SCHOOL_ID PRE_BEH_SUS_DESC PRE_BEH_DET_DESC
PRE_BEH_OFF_DESC PRE_SCENARIO POST_BEH_SUS_DESC POST_BEH_DET_DESC POST_BEH_OFF_DESC POST_SCENARIO
ENROLLED_DAYS ENROLLED_DAYS_CATEGORIES TTL_TIME DOSAGE_CATEGORIES Attendance_IA ELA_IA Math_IA Behavior_IA INDICATOR_ID
B_RULE_VAL1 B_RULE_VAL2 B_RULE_VAL3 B_RULE_VAL4 B_RULE_VAL5 GRADE_ID_RECODE EOY_MET_56_DAYS DN_SCHOOL_BY_GRADE
EOY_IN_IOG_GRADE_RANGE.
***** Rename linking ID variable.
RENAME VARIABLES (STUDENT_ID = cysdStudentID) (PRE_BEH_VALUE = BEHSCH_PRE_FREQ_DESC) (PRE_BEH_SUS = BEHSCH_PRE_SUS)
(PRE_BEH_DET = BEHSCH_PRE_DET) (PRE_BEH_OFF = BEHSCH_PRE_OFF) (POST_BEH_VALUE = BEHSCH_POST_FREQ_DESC)
(POST_BEH_SUS = BEHSCH_POST_SUS) (POST_BEH_DET = BEHSCH_POST_DET) (POST_BEH_OFF = BEHSCH_POST_OFF)
(PRE_BEH_OFF_CAT = BEHSCH_PRE_OFF_CAT) (PRE_BEH_DET_CAT = BEHSCH_PRE_DET_CAT) (PRE_BEH_SUS_CAT = BEHSCH_PRE_SUS_CAT)
(POST_BEH_OFF_CAT = BEHSCH_POST_OFF_CAT) (POST_BEH_DET_CAT = BEHSCH_POST_DET_CAT)
(POST_BEH_SUS_CAT = BEHSCH_POST_SUS_CAT) (EOY_OFF_FromZero = BEHSCH_EOY_OFF_FromZero)
(EOY_DET_FromZero = BEHSCH_EOY_DET_FromZero) (EOY_SUS_FromZero = BEHSCH_EOY_SUS_FromZero)
(EOY_OFF_FromGTZero = BEHSCH_EOY_OFF_FromGTZero) (EOY_DET_FromGTZero = BEHSCH_EOY_DET_FromGTZero)
(EOY_SUS_FromGTZero = BEHSCH_EOY_SUS_FromGTZero).
***** Add variable labels for existing variables.
VARIABLE LABELS BEHSCH_PRE_FREQ_DESC "Behavior (School-Based): pre time period"
BEHSCH_PRE_SUS "Behavior (School-Based): pre number of suspensions"
BEHSCH_PRE_DET "Behavior (School-Based): pre number of detentions"
BEHSCH_PRE_OFF "Behavior (School-Based): pre number of office referrals"
BEHSCH_POST_FREQ_DESC "Behavior (School-Based): post time period"
BEHSCH_POST_SUS "Behavior (School-Based): post number of suspensions"
BEHSCH_POST_DET "Behavior (School-Based): post number of detentions"
BEHSCH_POST_OFF "Behavior (School-Based): post number of office referrals"
BEHSCH_PRE_OFF_CAT "Behavior (School-Based): pre number of office referrals (categories)"
BEHSCH_PRE_DET_CAT "Behavior (School-Based): pre number of detentions (categories)"
BEHSCH_PRE_SUS_CAT "Behavior (School-Based): pre number of suspensions (categories)"
BEHSCH_POST_OFF_CAT "Behavior (School-Based): post number of office referrals (categories)"
BEHSCH_POST_DET_CAT "Behavior (School-Based): post number of detentions (categories)"
BEHSCH_POST_SUS_CAT "Behavior (School-Based): post number of suspensions (categories)"
BEHSCH_EOY_OFF_FromZero "Behavior (School-Based): change in office referrals (students starting with zero referrals)"
BEHSCH_EOY_DET_FromZero "Behavior (School-Based): change in detentions (students starting with zero referrals)"
BEHSCH_EOY_SUS_FromZero "Behavior (School-Based): change in suspensions (students starting with zero suspensions)"
BEHSCH_EOY_OFF_FromGTZero "Behavior (School-Based): change in office referrals (students starting with > zero referrals)"
BEHSCH_EOY_DET_FromGTZero "Behavior (School-Based): change in detentions (students starting with > zero detentions)"
BEHSCH_EOY_SUS_FromGTZero "Behavior (School-Based): change in suspensions (students starting with > zero suspensions)".
EXECUTE.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cysdStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = BEHSCHPerf
   /BY cysdStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the attendance dataset.
DATASET CLOSE BEHSCHPerf.

************************************************************************************************************************************************************************************
***** Merge in Diplomas Now attendance and behavior performance data.
************************************************************************************************************************************************************************************

***** Prep Diplomas Now attendance and behavior data file for merge.
DATASET ACTIVATE DNATTBEH.
***** Delete unnecessary variables.
DELETE VARIABLES Location School LocalStudentID StudentGrade ATTFLMetDosage BEHFLMetDosage DNSchool.
***** Rename variables.
RENAME VARIABLES (Q1AverageDailyAttendance = DNATTQ1ADA) (Q4AverageDailyAttendance = DNATTQ4ADA)
(@1213AverageDailyAttendance = DNATTPrYrADA) (@1314AverageDailyAttendance = DNATTCumulADA)
(Q1SuspensionsNum = DNBEHQ1SUS) (Q4SuspensionsNum = DNBEHQ4SUS).
***** Add variable labels for existing variables.
VARIABLE LABELS DNATTQ1ADA "Diplomas Now: Attendance: Q1 Average Daily Attendance"
   DNATTQ4ADA "Diplomas Now: Attendance: Q4 Average Daily Attendance"
   DNATTPrYrADA "Diplomas Now: Attendance: Prior Year Average Daily Attendance"
   DNATTCumulADA "Diplomas Now: Attendance: Current Year Cumulative ADA"
   DNBEHQ1SUS "Diplomas Now: Behavior: Q1 Suspensions"
   DNBEHQ4SUS "Diplomas Now: Behavior: Q4 Suspensions".
EXECUTE.
SORT CASES BY cyStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cyStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = DNATTBEH
   /BY cyStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the DN attendance/behavior data file.
DATASET CLOSE DNATTBEH.

************************************************************************************************************************************************************************************
***** Merge in DESSA data.
************************************************************************************************************************************************************************************

***** Prep DESSA data file for merge.
DATASET ACTIVATE DESSA.
***** Delete unnecessary variables.
DELETE VARIABLES DataDescription ProgramId ProgramName SiteId SiteName GroupId GroupName RatingYear ChildId ChildStatus ExternalId ChildLN
ChildFN ChildMN ChildGender ChildBirth RaterId RaterName RaterGender RaterType RaterDescription RatingId RatingStatus RatingPeriod RecordForm
AgeNormsTable AgeAtRatingMonths InRaw InTScore InPercentile InDescription ScRaw ScTScore ScPercentile SCDescription AtRaw AtTScore
ATPercentile ATDescription TpfRaw TpfTScore TpfPercentile TpfDescription BCRaw BCTScore BCPercentile BCDescription PrRaw PrTScore PrPercentile
PrDescription OtRaw OtTScore OtPercentile OtDescription GbRaw GbTScore GbPercentile GbDescription SoRaw SoTScore SoPercentile SoDescription
DmRaw DmTScore DmPercentile DmDescription RsRaw RsTScore RsPercentile RsDescription SaRaw SaTScore SaPercentile SaDescription SmRaw
SmTScore SmPercentile SmDescription LastUpdate OriginDate Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21
Q22 Q23 Q24 Q25 Q26 Q27 Q28 Q29 Q30 Q31 Q32 Q33 Q34 Q35 Q36 Q37 Q38 Q39 Q40 Q41 Q42 Q43 Q44 Q45 Q46 Q47 Q48 Q49 Q50 Q51 Q52 Q53
Q54 Q55 Q56 Q57 Q58 Q59 Q60 Q61 Q62 Q63 Q64 Q65 Q66 Q67 Q68 Q69 Q70 Q71 Q72.
***** Select only rows with an identified CY student ID.
SELECT IF (cyStudentID ~= "").
EXECUTE.
***** Rename variables.
RENAME VARIABLES (RatingDate = DESSARatingDate) (SecRaw = DESSARaw) (SecTScore = DESSATScore) (SecPercentile = DESSAPercentile)
(SecDescription = DESSADescription).
***** Add variable labels for existing variables.
VARIABLE LABELS DESSARatingDate "Date of DESSA administration"
   DESSARaw "Raw DESSA Score"
   DESSATScore "DESSA T Score"
   DESSAPercentile "DESSA Percentile"
   DESSADescription "DESSA Category".
EXECUTE.
***** Select first and last DESSA administration.
*****     Set initial value for last data point tag.
COMPUTE DP2Flag = 2.
EXECUTE.
*****     Sort cases, by student ID, descending by assessment date -- this should leave only the most recent assessment tagged in a variable for data point 2.
SORT CASES BY cyStudentID (A) DESSARatingDate (D).
DO IF (cyStudentID = LAG(cyStudentID)).
COMPUTE DP2Flag = 0.
END IF.
EXECUTE.
*****     Set initial value for 1st data point tag.
COMPUTE DP1Flag = 1.
EXECUTE.
*****     Sort cases, by student ID, ascending by assessment date -- this should leave only the oldest assessment tagged in a variable for data point 1.
SORT CASES BY cyStudentID (A) DESSARatingDate (A).
DO IF (cyStudentID = LAG(cyStudentID)).
COMPUTE DP1Flag = 0.
END IF.
EXECUTE.
*****     Smoosh data point tag variables 1 and 2 into a single variable -- any students with only one data point will have that data point tagged as data point 1.
COMPUTE DPALLFlag = DP2Flag.
EXECUTE.
RECODE DP1Flag (1=1) INTO DPALLFlag.
EXECUTE.
*Select first and last data points only.
SELECT IF (DPALLFlag = 1 | DPALLFlag = 2).
EXECUTE.
ALTER TYPE DPALLFlag (F1.0).
***** Restructure dataset so that each row is a unique student with a first and last test administration.
SORT CASES BY cyStudentID (A) DPALLFlag (A).
EXECUTE.
CASESTOVARS
 /ID=cyStudentID
 /AUTOFIX = NO
 /COUNT = DESSADPCount
 /INDEX = DPALLFlag
	/DROP = DP1Flag DP2Flag.
DATASET NAME DESSA.
***** Calculate number of days between DESSA administrations.
COMPUTE DESSARatingDateDiff = DATEDIFF(DESSARatingDate.2, DESSARatingDate.1, "days").
EXECUTE.
SORT CASES BY cyStudentID (A).
EXECUTE.

***** Prep final dataset for merge.
DATASET ACTIVATE FINALDATASET.
SORT CASES BY cyStudentID (A).
EXECUTE.

***** Merge student IDs to final dataset.
MATCH FILES /FILE = FINALDATASET
   /TABLE = DESSA
   /BY cyStudentID.
DATASET NAME FINALDATASET.
EXECUTE.

***** No longer need the DESSA data file.
DATASET CLOSE DESSA.

************************************************************************************************************************************************************************************
***** Calculate Met/Not Met Enrollment and Dosage Variables.
************************************************************************************************************************************************************************************

****************************************************************************************************
***** TEMP FIXES:.
*****     Overriding Q4 dosage goals to 6 hours for DN schools, with the exception.
*****          of CY Columbus (Linden McKinley and South HS), CY Jacksonville (Andrew Jackson HS),.
*****          and CY Tulsa (Clinton MS).
DO IF (DNSchool = 1 & cyschSchoolRefID ~= "001U0000008x3NoIAI" & cyschSchoolRefID ~= "001U000000O3C8PIAV" & cyschSchoolRefID ~= "001U000000EJ6m5IAD" & cyschSchoolRefID ~= "001U000000YueJpIAJ").
COMPUTE TEAMELAQ4DoseGoal = 6.
COMPUTE TEAMMTHQ4DoseGoal = 6.
COMPUTE TEAMELAQ4DoseGoalMin = TEAMELAQ4DoseGoal * 60.
COMPUTE TEAMMTHQ4DoseGoalMin = TEAMMTHQ4DoseGoal * 60.
END IF.
EXECUTE.
****************************************************************************************************

***** Calculate Met/Not Met Enrollment Variables -- ALL STUDENTS -- USE FOR DATA ENTRY MONITORING.
IF (LITEnroll >= 30 & EnrollDate.LIT >= DATE.MDY(07,1,2013) & ExitDate.LIT <= DATE.MDY(07,01,2014)) LITMet30EnrollALL = 1.
IF (LITEnroll < 30 & EnrollDate.LIT >= DATE.MDY(07,1,2013) & ExitDate.LIT <= DATE.MDY(07,01,2014)) LITMet30EnrollALL = 0.
IF (MTHEnroll >= 30 & EnrollDate.MTH >= DATE.MDY(07,1,2013) & ExitDate.MTH <= DATE.MDY(07,01,2014)) MTHMet30EnrollALL = 1.
IF (MTHEnroll < 30 & EnrollDate.MTH >= DATE.MDY(07,1,2013) & ExitDate.MTH <= DATE.MDY(07,01,2014)) MTHMet30EnrollALL = 0.
IF (ATTEnroll >= 30 & EnrollDate.ATT >= DATE.MDY(07,1,2013) & ExitDate.ATT <= DATE.MDY(07,01,2014)) ATTMet30EnrollALL = 1.
IF (ATTEnroll < 30 & EnrollDate.ATT >= DATE.MDY(07,1,2013) & ExitDate.ATT <= DATE.MDY(07,01,2014)) ATTMet30EnrollALL = 0.
IF (BEHEnroll >= 30  & EnrollDate.BEH >= DATE.MDY(07,1,2013) & ExitDate.BEH <= DATE.MDY(07,01,2014)) BEHMet30EnrollALL = 1.
IF (BEHEnroll < 30 & EnrollDate.BEH >= DATE.MDY(07,1,2013) & ExitDate.BEH <= DATE.MDY(07,01,2014)) BEHMet30EnrollALL = 0.
VARIABLE LABELS LITMet30EnrollALL "Number of Students Enrolled 30+ Days (ELA/Literacy, with overlap, regardless of IA-assignment)"
   MTHMet30EnrollALL "Number of Students Enrolled 30+ Days (Math, with overlap, regardless of IA-assignment)"
   ATTMet30EnrollALL "Number of Students Enrolled 30+ Days (Attendance, with overlap, regardless of IA-assignment)"
   BEHMet30EnrollALL "Number of Students Enrolled 30+ Days (Behavior, with overlap, regardless of IA-assignment)".
VALUE LABELS LITMet30EnrollALL MTHMet30EnrollALL ATTMet30EnrollALL BEHMet30EnrollALL 0 "Enrolled Less Than 30 Days"
   1 "Enrolled 30+ Days".
EXECUTE.

***** Calculate Met/Not Met Enrollment Variables -- IA-ASSIGNED STUDENTS ONLY, USE THESE FOR ANALYSIS TO COUNT/SELECT OFFICIAL FL #s.
IF (LITEnroll >= 30 & IALIT = 1 & EnrollDate.LIT >= DATE.MDY(07,1,2013) & ExitDate.LIT <= DATE.MDY(07,01,2014)) LITMet30Enroll = 1.
IF (LITEnroll < 30 & IALIT = 1 & EnrollDate.LIT >= DATE.MDY(07,1,2013) & ExitDate.LIT <= DATE.MDY(07,01,2014)) LITMet30Enroll = 0.
IF (MTHEnroll >= 30 & IAMTH = 1 & EnrollDate.MTH >= DATE.MDY(07,1,2013) & ExitDate.MTH <= DATE.MDY(07,01,2014)) MTHMet30Enroll = 1.
IF (MTHEnroll < 30 & IAMTH = 1 & EnrollDate.MTH >= DATE.MDY(07,1,2013) & ExitDate.MTH <= DATE.MDY(07,01,2014)) MTHMet30Enroll = 0.
IF (ATTEnroll >= 30 & IAATT = 1 & EnrollDate.ATT >= DATE.MDY(07,1,2013) & ExitDate.ATT <= DATE.MDY(07,01,2014)) ATTMet30Enroll = 1.
IF (ATTEnroll < 30 & IAATT = 1 & EnrollDate.ATT >= DATE.MDY(07,1,2013) & ExitDate.ATT <= DATE.MDY(07,01,2014)) ATTMet30Enroll = 0.
IF (BEHEnroll >= 30 & IABEH = 1 & EnrollDate.BEH >= DATE.MDY(07,1,2013) & ExitDate.BEH <= DATE.MDY(07,01,2014)) BEHMet30Enroll = 1.
IF (BEHEnroll < 30 & IABEH = 1 & EnrollDate.BEH >= DATE.MDY(07,1,2013) & ExitDate.BEH <= DATE.MDY(07,01,2014)) BEHMet30Enroll = 0.
VARIABLE LABELS LITMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (ELA/Literacy, with overlap)"
   MTHMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Math, with overlap)"
   ATTMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Attendance, with overlap)"
   BEHMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Behavior, with overlap)".
VALUE LABELS LITMet30Enroll MTHMet30Enroll ATTMet30Enroll BEHMet30Enroll 0 "IA assigned, Enrolled Less Than 30 Days"
   1 "Official FL: IA-assigned, Enrolled 30+ Days".
EXECUTE.

***** Calculate Met/Not Met Dosage Variables.
***** Attendance/Behavior "Dosage".
IF (ATTMet30Enroll = 1 & ATTEnroll >= 56) ATTMet56Dose = 1.
IF (ATTMet30Enroll = 1 & ATTEnroll < 56) ATTMet56Dose = 0.
IF (BEHMet30Enroll = 1 & BEHEnroll >= 56) BEHMet56Dose = 1.
IF (BEHMet30Enroll = 1 & BEHEnroll < 56) BEHMet56Dose = 0.
VARIABLE LABELS ATTMet56Dose "DOSAGE ACTUAL\nNumber of Students Enrolled 56+ Days (Attendance, with overlap)"
   BEHMet56Dose "DOSAGE ACTUAL\nNumber of Students Enrolled 56+ Days (Behavior, with overlap)".
VALUE LABELS ATTMet56Dose 0 "Did not meet 56+ day dosage threshold"
   1 "Met 56+ day dosage threshold".
VALUE LABELS BEHMet56Dose 0 "Did not meet 56+ day dosage threshold"
   1 "Met 56+ day dosage threshold".
*****     RSO - Q2 Dosage Goals.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT >= TEAMELAQ2DoseGoalMin)) LITMetQ2Dose = 1.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT < TEAMELAQ2DoseGoalMin)) LITMetQ2Dose = 0.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH >= TEAMMTHQ2DoseGoalMin)) MTHMetQ2Dose = 1.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH < TEAMMTHQ2DoseGoalMin)) MTHMetQ2Dose = 0.
VARIABLE LABELS LITMetQ2Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q2 Dosage Benchmark (with overlap)"
   MTHMetQ2Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q2 Dosage Benchmark (with overlap)".
VALUE LABELS LITMetQ2Dose 0 "Did not meet Q2 literacy dosage goal"
   1 "Met Q2 literacy dosage goal".
VALUE LABELS MTHMetQ2Dose 0 "Did not meet Q2 math dosage goal"
   1 "Met Q2 math dosage goal".
*****     RSO - Q3 Dosage Goals.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT >= TEAMELAQ3DoseGoalMin)) LITMetQ3Dose = 1.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT < TEAMELAQ3DoseGoalMin)) LITMetQ3Dose = 0.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH >= TEAMMTHQ3DoseGoalMin)) MTHMetQ3Dose = 1.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH < TEAMMTHQ3DoseGoalMin)) MTHMetQ3Dose = 0.
VARIABLE LABELS LITMetQ3Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q3 Dosage Benchmark (with overlap)"
   MTHMetQ3Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q3 Dosage Benchmark (with overlap)".
VALUE LABELS LITMetQ3Dose 0 "Did not meet Q3 literacy dosage goal"
   1 "Met Q3 literacy dosage goal".
VALUE LABELS MTHMetQ3Dose 0 "Did not meet Q3 math dosage goal"
   1 "Met Q3 math dosage goal".
EXECUTE.
*****     RSO - Q4 Dosage Goals.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT >= TEAMELAQ4DoseGoalMin)) LITMetQ4Dose = 1.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT < TEAMELAQ4DoseGoalMin)) LITMetQ4Dose = 0.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH >= TEAMMTHQ4DoseGoalMin)) MTHMetQ4Dose = 1.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH < TEAMMTHQ4DoseGoalMin)) MTHMetQ4Dose = 0.
VARIABLE LABELS LITMetQ4Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q4 Dosage Benchmark (with overlap)"
   MTHMetQ4Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q4 Dosage Benchmark (with overlap)".
VALUE LABELS LITMetQ4Dose 0 "Did not meet Q4 literacy dosage goal"
   1 "Met Q4 literacy dosage goal".
VALUE LABELS MTHMetQ4Dose 0 "Did not meet Q4 math dosage goal"
   1 "Met Q4 math dosage goal".
EXECUTE.
*****     Q4 Dosage Goals - STUDENTS MEETING HALFWAY DOSAGE POINT (primarily for AC purposes).
IF (LITMet30Enroll = 1 & (TotalDosage.LIT >= (TEAMELAQ4DoseGoalMin * 0.5))) LITMetQ4DoseHalf = 1.
IF (LITMet30Enroll = 1 & (TotalDosage.LIT < (TEAMELAQ4DoseGoalMin * 0.5))) LITMetQ4DoseHalf = 0.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH >= (TEAMMTHQ4DoseGoalMin * 0.5))) MTHMetQ4DoseHalf = 1.
IF (MTHMet30Enroll = 1 & (TotalDosage.MTH < (TEAMMTHQ4DoseGoalMin * 0.5))) MTHMetQ4DoseHalf = 0.
VARIABLE LABELS LITMetQ4DoseHalf "Number of Students Meeting HALF ELA/Literacy Q4 Dosage Benchmark (with overlap)"
   MTHMetQ4DoseHalf "Number of Students Meeting HALF Math Q4 Dosage Benchmark (with overlap)".
VALUE LABELS LITMetQ4DoseHalf 0 "Did not meet HALF Q4 literacy dosage goal"
   1 "Met HALF Q4 literacy dosage goal".
VALUE LABELS MTHMetQ4DoseHalf 0 "Did not meet HALF Q4 math dosage goal"
   1 "Met HALF Q4 math dosage goal".
EXECUTE.

************************************************************************************************************************************************************************************
***** Calculate additional variables -- FOR IOG and BOCY.
************************************************************************************************************************************************************************************

***** Default to grades 3-9 if missing info.
IF MISSING(TEAMIOGMinGrade) TEAMIOGMinGrade = 3.
IF MISSING(TEAMIOGMaxGrade) TEAMIOGMaxGrade = 9.
EXECUTE.
***** Create variable that indicates whether or not the student is in a grade level to be reported on for IOGs.
DO IF (StudentGrade >= TEAMIOGMinGrade & StudentGrade <= TEAMIOGMaxGrade).
COMPUTE IOGGradeCount = 1.
ELSE.
COMPUTE IOGGradeCount = 0.
END IF.
VARIABLE LABELS IOGGradeCount "Number of students that fall within grade range to be reported on for IOGs".
VALUE LABELS IOGGradeCount 0 "Does not fall within grade-level range for IOG reporting"
   1 "Falls within grade-level range for IOG reporting".
EXECUTE.

***** IOG Enrollment variables by lower vs. upper grade levels.
***** Literacy.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMet30Enroll = 1) IOG_LIT35_OfficialFL = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMet30Enroll = 1) IOG_LIT69_OfficialFL = 1.
***** Math.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMet30Enroll = 1) IOG_MTH35_OfficialFL = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMet30Enroll = 1) IOG_MTH69_OfficialFL = 1.
***** Attendance.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet30Enroll = 1) IOG_ATT35_OfficialFL = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet30Enroll = 1) IOG_ATT69_OfficialFL = 1.
***** Behavior.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & BEHMet30Enroll = 1) IOG_BEH35_OfficialFL = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & BEHMet30Enroll = 1) IOG_BEH69_OfficialFL = 1.
EXECUTE.
VARIABLE LABELS IOG_LIT35_OfficialFL "IOG: 3rd-5th Grade Literacy: Number of students on official focus lists"
   IOG_LIT69_OfficialFL "IOG: 6th-9th Grade Literacy: Number of students on official focus lists"
   IOG_MTH35_OfficialFL "IOG: 3rd-5th Grade Math: Number of students on official focus lists"
   IOG_MTH69_OfficialFL "IOG: 6th-9th Grade Math: Number of students on official focus lists"
   IOG_ATT35_OfficialFL "IOG: 3rd-5th Grade Attendance: Number of students on official focus lists"
   IOG_ATT69_OfficialFL "IOG: 6th-9th Grade Attendance: Number of students on official focus lists"
   IOG_BEH35_OfficialFL "IOG: 3rd-5th Grade Behavior: Number of students on official focus lists"
   IOG_BEH69_OfficialFL "IOG: 6th-9th Grade Bheavior: Number of students on official focus lists".
EXECUTE.

***** Literacy Assessments.
IF (NOT MISSING(LITAssess_PRE_VALUE_NUM) | NOT MISSING(LITAssess_POST_VALUE_NUM)) LITAssess_anyRawDP = 1.
IF (LITAssess_PRE_TRACK_EVAL ~= "" & LITAssess_POST_TRACK_EVAL ~= "") LITAssess_2PerfLvlDP = 1.
EXECUTE.
IF (LITAssess_2PerfLvlDP = 1 & (LITAssess_PRE_TRACK_EVAL = "SLIDING" | LITAssess_PRE_TRACK_EVAL = "OFF TRACK")) LITAssess_StartOffSlid = 1.
EXECUTE.
IF (LITAssess_StartOffSlid = 1 & LITAssess_POST_TRACK_EVAL = "ON TRACK") LITAssess_SOSMoveOn = 1.
EXECUTE.
***** Grades 3-5 Literacy: X% or more of students move from below benchmark on literacy skills assessment to at/above benchmark.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_anyRawDP = 1) IOG_LITAssess35_anyRawDP = 1.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_2PerfLvlDP = 1) IOG_LITAssess35_2PerfLvlDP = 1.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_StartOffSlid = 1) IOG_LITAssess35_StartOffSlid = 1.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_SOSMoveOn = 1) IOG_LITAssess35_SOSMoveOn = 1.
EXECUTE.
***** Grades 6-9 ELA/Literacy: X% or more of students move from below benchmark on literacy skills assessment to at/above benchmark.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_anyRawDP = 1) IOG_LITAssess69_anyRawDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_2PerfLvlDP = 1) IOG_LITAssess69_2PerfLvlDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_StartOffSlid = 1) IOG_LITAssess69_StartOffSlid = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & LITAssess_SOSMoveOn = 1) IOG_LITAssess69_SOSMoveOn = 1.
EXECUTE.
***** BOCY: WSWC-only, official focus list, met dosage, started off-track or sliding.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & (LITAssess_PRE_TRACK_EVAL = "SLIDING" | LITAssess_PRE_TRACK_EVAL = "OFF TRACK")) BOCY_LITAssess35_StartOffSlid = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & (LITAssess_PRE_TRACK_EVAL = "SLIDING" | LITAssess_PRE_TRACK_EVAL = "OFF TRACK")) BOCY_LITAssess69_StartOffSlid = 1.
EXECUTE.
VARIABLE LABELS LITAssess_anyRawDP "Number of students with at least one raw literacy assessment performance data point"
   LITAssess_2PerfLvlDP "Number of students with at least two literacy assessment performance level data points"
   LITAssess_StartOffSlid "Number of students who started off-track or sliding in literacy assessments"
   LITAssess_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in literacy assessments"
   IOG_LITAssess35_anyRawDP "IOG: 3rd-5th Grade Literacy Assessments: Number of students who had at least one raw performance data point"
   IOG_LITAssess35_2PerfLvlDP "IOG: 3rd-5th Grade Literacy Assessments: Number of students who had at least two performance level data points"
   IOG_LITAssess35_StartOffSlid "IOG: 3rd-5th Grade Literacy Assessments: Number of students who started off-track or sliding"
   IOG_LITAssess35_SOSMoveOn "IOG: 3rd-5th Grade Literacy Assessments: Number of students who started off-track or sliding and moved back on-track"
   IOG_LITAssess69_anyRawDP "IOG: 6th-9th Grade Literacy Assessments: Number of students who had at least one raw performance data point"
   IOG_LITAssess69_2PerfLvlDP "IOG: 6th-9th Grade Literacy Assessments: Number of students who had at least two performance level data points"
   IOG_LITAssess69_StartOffSlid "IOG: 6th-9th Grade Literacy Assessments: Number of students who started off-track or sliding"
   IOG_LITAssess69_SOSMoveOn "IOG: 6th-9th Grade Literacy Assessments: Number of students who started off-track or sliding and moved back on-track"
   BOCY_LITAssess35_StartOffSlid "Best of City Year: 3rd-5th Grade Literacy Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   BOCY_LITAssess69_StartOffSlid "Best of City Year: 6th-9th Grade Literacy Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding".
EXECUTE.

***** ELA Course Grades.
IF (ELACG_PRE_LETTER_VIEW ~= "" | ELACG_POST_LETTER_VIEW ~= "") ELACG_anyRawDP = 1.
IF (ELACG_PRE_TRACK ~= "" & ELACG_POST_TRACK ~= "") ELACG_2PerfLvlDP = 1.
EXECUTE.
IF (ELACG_2PerfLvlDP = 1 & (ELACG_PRE_TRACK = "SLIDING" | ELACG_PRE_TRACK = "OFF TRACK")) ELACG_StartOffSlid = 1.
EXECUTE.
IF (ELACG_StartOffSlid = 1 & ELACG_POST_TRACK = "ON TRACK") ELACG_SOSMoveOn = 1.
EXECUTE.
***** Grades 6-9 ELA/Literacy: 50% or more of students move from an ELA course grade of “D” or lower to a “C” or higher.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & ELACG_anyRawDP = 1) IOG_ELACG69_anyRawDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & ELACG_2PerfLvlDP = 1) IOG_ELACG69_2PerfLvlDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & ELACG_StartOffSlid = 1) IOG_ELACG69_StartOffSlid = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & LITMetQ4Dose = 1 & ELACG_SOSMoveOn = 1) IOG_ELACG69_SOSMoveOn = 1.
EXECUTE.
VARIABLE LABELS ELACG_anyRawDP "Number of students with at least one ELA course grade performance data point"
   ELACG_2PerfLvlDP "Number of students with at least two ELA course grade performance level data points"
   ELACG_StartOffSlid "Number of students who started off-track or sliding in ELA course grades"
   ELACG_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in ELA course grades"
   IOG_ELACG69_anyRawDP "IOG: 6th-9th Grade ELA Course Grades: Number of students who had at least one course grade performance data point"
   IOG_ELACG69_2PerfLvlDP "IOG: 6th-9th Grade ELA Course Grades: Number of students who had at least two performance level data points"
   IOG_ELACG69_StartOffSlid "IOG: 6th-9th Grade ELA Course Grades: Number of students who started off-track or sliding"
   IOG_ELACG69_SOSMoveOn "IOG: 6th-9th Grade ELA Course Grades: Number of students who started off-track or sliding and moved back on-track".
EXECUTE.

***** Math Assessments.
IF (NOT MISSING(MTHAssess_PRE_VALUE_NUM) | NOT MISSING(MTHAssess_POST_VALUE_NUM)) MTHAssess_anyRawDP = 1.
IF (MTHAssess_PRE_TRACK_EVAL ~= "" & MTHAssess_POST_TRACK_EVAL ~= "") MTHAssess_2PerfLvlDP = 1.
EXECUTE.
IF (MTHAssess_2PerfLvlDP = 1 & (MTHAssess_PRE_TRACK_EVAL = "SLIDING" | MTHAssess_PRE_TRACK_EVAL = "OFF TRACK")) MTHAssess_StartOffSlid = 1.
EXECUTE.
IF (MTHAssess_StartOffSlid = 1 & MTHAssess_POST_TRACK_EVAL = "ON TRACK") MTHAssess_SOSMoveOn = 1.
EXECUTE.
***** Grades 3-5 Math: 25% or more of students move from below benchmark on math skills assessment to at/above benchmark.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_anyRawDP = 1) IOG_MTHAssess35_anyRawDP = 1.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_2PerfLvlDP = 1) IOG_MTHAssess35_2PerfLvlDP = 1.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_StartOffSlid = 1) IOG_MTHAssess35_StartOffSlid = 1.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_SOSMoveOn = 1) IOG_MTHAssess35_SOSMoveOn = 1.
EXECUTE.
***** Grades 6-9 Math: 20% or more of students on official focus lists meeting the dosage threshold move from below benchmark on math skills assessment to at/above benchmark.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_anyRawDP = 1) IOG_MTHAssess69_anyRawDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_2PerfLvlDP = 1) IOG_MTHAssess69_2PerfLvlDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_StartOffSlid = 1) IOG_MTHAssess69_StartOffSlid = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHAssess_SOSMoveOn = 1) IOG_MTHAssess69_SOSMoveOn = 1.
EXECUTE.
***** BOCY: WSWC-only, official focus list, met dosage, started off-track or sliding.
IF (StudentGrade <= 5 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & (MTHAssess_PRE_TRACK_EVAL = "SLIDING" | MTHAssess_PRE_TRACK_EVAL = "OFF TRACK")) BOCY_MTHAssess35_StartOffSlid = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & (MTHAssess_PRE_TRACK_EVAL = "SLIDING" | MTHAssess_PRE_TRACK_EVAL = "OFF TRACK")) BOCY_MTHAssess69_StartOffSlid = 1.
EXECUTE.
VARIABLE LABELS MTHAssess_anyRawDP "Number of students with at least one raw math assessment performance data point"
   MTHAssess_2PerfLvlDP "Number of students with at least two math assessment performance level data points"
   MTHAssess_StartOffSlid "Number of students who started off-track or sliding in math assessments"
   MTHAssess_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in math assessments"
   IOG_MTHAssess35_anyRawDP "IOG: 3rd-5th Grade Math Assessments: Number of students who had at least one raw performance data point"
   IOG_MTHAssess35_2PerfLvlDP "IOG: 3rd-5th Grade Math Assessments: Number of students who had at least two performance level data points"
   IOG_MTHAssess35_StartOffSlid "IOG: 3rd-5th Grade Math Assessments: Number of students who started off-track or sliding"
   IOG_MTHAssess35_SOSMoveOn "IOG: 3rd-5th Grade Math Assessments: Number of students who started off-track or sliding and moved back on-track"
   IOG_MTHAssess69_anyRawDP "IOG: 6th-9th Grade Math Assessments: Number of students who had at least one raw performance data point"
   IOG_MTHAssess69_2PerfLvlDP "IOG: 6th-9th Grade Math Assessments: Number of students who had at least two performance level data points"
   IOG_MTHAssess69_StartOffSlid "IOG: 6th-9th Grade Math Assessments: Number of students who started off-track or sliding"
   IOG_MTHAssess69_SOSMoveOn "IOG: 6th-9th Grade Math Assessments: Number of students who started off-track or sliding and moved back on-track"
   BOCY_MTHAssess35_StartOffSlid "Best of City Year: 3rd-5th Grade Math Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   BOCY_MTHAssess69_StartOffSlid "Best of City Year: 6th-9th Grade Math Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding".
EXECUTE.

***** Math Course Grades.
IF (MTHCG_PRE_LETTER_VIEW ~= "" | MTHCG_POST_LETTER_VIEW ~= "") MTHCG_anyRawDP = 1.
IF (MTHCG_PRE_TRACK ~= "" & MTHCG_POST_TRACK ~= "") MTHCG_2PerfLvlDP = 1.
EXECUTE.
IF (MTHCG_2PerfLvlDP = 1 & (MTHCG_PRE_TRACK = "SLIDING" | MTHCG_PRE_TRACK = "OFF TRACK")) MTHCG_StartOffSlid = 1.
EXECUTE.
IF (MTHCG_StartOffSlid = 1 & MTHCG_POST_TRACK = "ON TRACK") MTHCG_SOSMoveOn = 1.
EXECUTE.
***** Grades 6-9 Math: 50% or more of students on official focus lists meeting the dosage threshold move from a math course grade of “D” or lower to a “C” or higher.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHCG_anyRawDP = 1) IOG_MTHCG69_anyRawDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHCG_2PerfLvlDP = 1) IOG_MTHCG69_2PerfLvlDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHCG_StartOffSlid = 1) IOG_MTHCG69_StartOffSlid = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & MTHMetQ4Dose = 1 & MTHCG_SOSMoveOn = 1) IOG_MTHCG69_SOSMoveOn = 1.
EXECUTE.
VARIABLE LABELS MTHCG_anyRawDP "Number of students with at least one math course grade performance data point"
   MTHCG_2PerfLvlDP "Number of students with at least two math course grade performance level data points"
   MTHCG_StartOffSlid "Number of students who started off-track or sliding in math course grades"
   MTHCG_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in math course grades"
   IOG_MTHCG69_anyRawDP "IOG: 6th-9th Grade Math Course Grades: Number of students who had at least one course grade performance data point"
   IOG_MTHCG69_2PerfLvlDP "IOG: 6th-9th Grade Math Course Grades: Number of students who had at least two performance level data points"
   IOG_MTHCG69_StartOffSlid "IOG: 6th-9th Grade Math Course Grades: Number of students who started off-track or sliding"
   IOG_MTHCG69_SOSMoveOn "IOG: 6th-9th Grade Math Course Grades: Number of students who started off-track or sliding and moved back on-track".
EXECUTE.

***** Attendance.
IF (NOT MISSING(ATT_PRE_ADA) | NOT MISSING(ATT_POST_ADA)) ATT_anyRawDP = 1.
IF (ATT_PRE_TRACK ~= "" & ATT_POST_TRACK ~= "") ATT_2PerfLvlDP = 1.
EXECUTE.
IF (ATT_PRE_ADA < 0.9 & NOT MISSING(ATT_POST_ADA)) ATT_StartLT90ADA = 1.
EXECUTE.
IF (ATT_StartLT90ADA = 1 & ATT_POST_ADA >= 0.9) ATT_SOSMoveOn = 1.
EXECUTE.
***** Grades 6-9 Attendance: Of students on official Attendance focus lists meeting the dosage threshold: 35% move from below 90% ADA to at or above 90% ADA.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet56Dose = 1 & ATT_anyRawDP = 1) IOG_ATT69_anyRawDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet56Dose = 1 & ATT_2PerfLvlDP = 1) IOG_ATT69_2PerfLvlDP = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet56Dose = 1 & ATT_StartLT90ADA = 1) IOG_ATT69_StartLT90ADA = 1.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet56Dose = 1 & ATT_SOSMoveOn = 1) IOG_ATT69_SOSMoveOn = 1.
EXECUTE.
***** BOCY: WSWC-only, official focus list, enrolled 56+ days, started <90% ADA.
IF (StudentGrade >= 6 & IOGGradeCount = 1 & DN_SCHOOL_BY_GRADE = 0 & ATTMet56Dose = 1 & ATT_PRE_ADA < 0.9) BOCY_ATT69_StartLT90ADA = 1.
EXECUTE.
VARIABLE LABELS ATT_anyRawDP "Number of students with at least one attendance (ADA) performance data point"
   ATT_2PerfLvlDP "Number of students with at least two attendance (ADA) performance level data points"
   ATT_StartLT90ADA "Number of students who started with less than 90% average daily attendance"
   ATT_SOSMoveOn "Number of students who started below 90% ADA and moved to at or above 90% ADA"
   IOG_ATT69_anyRawDP "IOG: 6th-9th Grade Attendance: Number of students who had at least one ADA performance data point"
   IOG_ATT69_2PerfLvlDP "IOG: 6th-9th Grade Attendance: Number of students who had at least two performance level data points"
   IOG_ATT69_StartLT90ADA "IOG: 6th-9th Grade Attendance: Number of students who started with less than 90% average daily attendance"
   IOG_ATT69_SOSMoveOn "IOG: 6th-9th Grade Attendance: Number of students who started below 90% ADA and moved to at or above 90% ADA"
   BOCY_ATT69_StartLT90ADA "Best of City Year: 6th-9th Grade Attendance: Number of students on official focus lists, enrolled 56+ days, and started with less than 90% average daily attendance".
EXECUTE.

************************************************************************************************************************************************************************************
***** Calculate additional variables -- FOR AC REPORTING.
************************************************************************************************************************************************************************************

***** Enrolled in LIT or MTH.
IF (ACreportLIT = 1) ACLITMet30Enroll = ACreportLIT * LITMet30Enroll.
IF (ACreportMTH = 1) ACMTHMet30Enroll = ACreportMTH * MTHMet30Enroll.
IF ((ACLITMet30Enroll = 1) | (ACMTHMet30Enroll = 1)) ACLITorMTHMet30Enroll = 1.
EXECUTE.
IF ((ACLITorMTHMet30Enroll ~= 1) & (ACLITMet30Enroll = 0 | ACMTHMet30Enroll = 0)) ACLITorMTHMet30Enroll = 0.
VARIABLE LABELS ACLITMet30Enroll "Non-unique number of students enrolled on official focus lists for literacy (AC reporting)"
   ACMTHMet30Enroll "Non-unique number of students enrolled on official focus lists for math (AC reporting)"
   ACLITorMTHMet30Enroll "ACTUAL ED1 Academic:\nUnique number of students enrolled on official focus lists for literacy and/or math".
VALUE LABELS ACLITMet30Enroll 0 "AmeriCorps Reporting: Did not meet official focus list criteria for literacy"
   1 "AmeriCorps Reporting: On official focus list for literacy".
VALUE LABELS ACMTHMet30Enroll 0 "AmeriCorps Reporting: Did not meet official focus list criteria for math"
   1 "AmeriCorps Reporting: On official focus list for math".
VALUE LABELS ACLITorMTHMet30Enroll 0 "AmeriCorps Reporting: Did not meet official focus list criteria for literacy or math"
   1 "AmeriCorps Reporting: On official focus list for literacy and/or math".
EXECUTE.

***** Met Enroll/Dosage for LIT or MTH.
IF (ACLITMet30Enroll = 1) ACLITMetQ4Dose = ACLITMet30Enroll * LITMetQ4Dose.
IF (ACMTHMet30Enroll = 1) ACMTHMetQ4Dose = ACMTHMet30Enroll * MTHMetQ4Dose.
IF (ACLITMetQ4Dose = 1 | ACMTHMetQ4Dose = 1) ACLITorMTHMetQ4Dose = 1.
EXECUTE.
IF (ACLITorMTHMetQ4Dose ~= 1 & (ACLITMetQ4Dose = 0 | ACMTHMetQ4Dose = 0)) ACLITorMTHMetQ4Dose = 0.
VARIABLE LABELS ACLITMetQ4Dose "Non-unique number of students on official focus lists who met dosage thresholds for literacy (AC reporting)"
   ACMTHMetQ4Dose "Non-unique number of students on official focus lists who met dosage thresholds for math (AC reporting)"
   ACLITorMTHMetQ4Dose "ACTUAL ED2 Academic:\nUnique number of students on official focus lists who met final dosage thresholds for literacy and/or math".
VALUE LABELS ACLITMetQ4Dose 0 "AmeriCorps Reporting: Official focus list, did not meet dosage threshold for literacy"
   1 "AmeriCorps Reporting: Official focus list, met dosage threshold for literacy".
VALUE LABELS ACMTHMetQ4Dose 0 "AmeriCorps Reporting: Official focus list, did not meet dosage threshold for math"
   1 "AmeriCorps Reporting: Official focus list, met dosage threshold for math".
VALUE LABELS ACLITorMTHMetQ4Dose 0 "On official focus list for literacy and/or math, did not meet dosage threshold"
   1 "On official focus list for literacy and/or math, met dosage threshold".
EXECUTE.

***** Met Enroll/HALF DOSAGE for LIT or MTH.
IF (ACLITMet30Enroll = 1) ACLITMetQ4DoseHalf = ACLITMet30Enroll * LITMetQ4DoseHalf.
IF (ACMTHMet30Enroll = 1) ACMTHMetQ4DoseHalf = ACMTHMet30Enroll * MTHMetQ4DoseHalf.
IF (ACLITMetQ4DoseHalf = 1 | ACMTHMetQ4DoseHalf = 1) ACLITorMTHMetQ4DoseHalf = 1.
EXECUTE.
IF (ACLITorMTHMetQ4DoseHalf ~= 1 & (ACLITMetQ4DoseHalf = 0 | ACMTHMetQ4DoseHalf = 0)) ACLITorMTHMetQ4DoseHalf = 0.
VARIABLE LABELS ACLITMetQ4DoseHalf "Non-unique number of students on official focus lists who met HALF dosage thresholds for literacy (AC reporting)"
   ACMTHMetQ4DoseHalf "Non-unique number of students on official focus lists who met HALF dosage thresholds for math (AC reporting)"
   ACLITorMTHMetQ4DoseHalf "Unique number of students on official focus lists who met HALF dosage thresholds for literacy and/or math".
VALUE LABELS ACLITMetQ4DoseHalf 0 "AmeriCorps Reporting: Official focus list, did not meet HALF dosage threshold for literacy"
   1 "AmeriCorps Reporting: Official focus list, met HALF dosage threshold for literacy".
VALUE LABELS ACMTHMetQ4DoseHalf 0 "AmeriCorps Reporting: Official focus list, did not meet HALF dosage threshold for math"
   1 "AmeriCorps Reporting: Official focus list, met HALF dosage threshold for math".
VALUE LABELS ACLITorMTHMetQ4DoseHalf 0 "On official focus list for literacy and/or math, did not meet HALF dosage threshold"
   1 "On official focus list for literacy and/or math, met HALF dosage threshold".
EXECUTE.

***** Enrolled in ATT or BEH.
IF (ACreportATT = 1) ACATTMet30Enroll = ACreportATT * ATTMet30Enroll.
IF (ACreportBEH = 1) ACBEHMet30Enroll = ACreportBEH * BEHMet30Enroll.
IF (ACATTMet30Enroll = 1 | ACBEHMet30Enroll = 1) ACATTorBEHMet30Enroll = 1.
EXECUTE.
IF ((ACATTorBEHMet30Enroll ~= 1) & (ACATTMet30Enroll = 0 | ACBEHMet30Enroll = 0)) ACATTorBEHMet30Enroll = 0.
VARIABLE LABELS ACATTMet30Enroll "Non-unique number of students enrolled on official focus lists for attendance (AC reporting)"
   ACBEHMet30Enroll "Non-unique number of students enrolled on official focus lists for behavior (AC reporting)"
   ACATTorBEHMet30Enroll "ACTUAL ED1 Student Engagement:\nUnique number of students enrolled on official focus lists for attendance and/or behavior".
VALUE LABELS ACATTMet30Enroll 0 "AmeriCorps Reporting: Did not meet official focus list criteria for attendance"
   1 "AmeriCorps Reporting: Met official focus list criteria for attendance".
VALUE LABELS ACBEHMet30Enroll 0 "AmeriCorps Reporting: Did not meet official focus list criteria for behavior"
   1 "AmeriCorps Reporting: Met official focus list criteria for behavior".
VALUE LABELS ACATTorBEHMet30Enroll 0 "AmeriCorps: Did not meet official focus list criteria for attendance or behavior"
   1 "AmeriCorps: On official focus list for attendance and/or behavior".
EXECUTE.

***** Met Enroll/Dosage for ATT or BEH.
IF (ACATTMet30Enroll = 1) ACATTMet56Dose = ACATTMet30Enroll * ATTMet56Dose.
IF (ACBEHMet30Enroll = 1) ACBEHMet56Dose = ACBEHMet30Enroll * BEHMet56Dose.
IF (ACATTMet56Dose = 1 | ACBEHMet56Dose = 1) ACATTorBEHMet56Dose = 1.
EXECUTE.
IF (ACATTorBEHMet56Dose ~= 1 & (ACATTMet56Dose = 0 | ACBEHMet56Dose = 0)) ACATTorBEHMet56Dose = 0.
VARIABLE LABELS ACATTMet56Dose "Non-unique number of students on official focus lists who met dosage thresholds for attendance (AC reporting)"
   ACBEHMet56Dose "Non-unique number of students on official focus lists who met dosage thresholds for behavior (AC reporting)"
   ACATTorBEHMet56Dose "ACTUAL ED2 Student Engagement:\nUnique number of students on official focus lists who met dosage thresholds for attendance and/or behavior".
VALUE LABELS ACATTMet56Dose 0 "AmeriCorps Reporting: Official focus list, did not meet dosage threshold for attendance"
   1 "AmeriCorps Reporting: Official focus list, met dosage threshold for attendance".
VALUE LABELS ACBEHMet56Dose 0 "AmeriCorps Reporting: Official focus list, did not meet dosage threshold for behavior"
   1 "AmeriCorps Reporting: Official focus list, met dosage threshold for behavior".
VALUE LABELS ACATTorBEHMet56Dose 0 "AmeriCorps: On official focus list for attendance and/or behavior, did not meet dosage threshold"
   1 "AmeriCorps: On official focus list for attendance and/or behavior, met dosage threshold".
EXECUTE.

***** What grade levels are we reporting on for AmeriCorps?.
DO IF (ACLITorMTHMet30Enroll = 1 | ACATTorBEHMet30Enroll = 1).
COMPUTE ACStudentGrade = StudentGrade.
END IF.
VARIABLE LABELS ACStudentGrade "Student Grade Levels".
EXECUTE.

************************************************************************************************************************************************************************************
***** Create additional variables.
************************************************************************************************************************************************************************************

***** Create regional variable.
RECODE Location ("Baton Rouge" = 4) ("Boston" = 3) ("Chicago" = 2) ("Cleveland" = 2) ("Columbia" = 4) ("Columbus" = 2) ("Denver" = 5) ("Detroit" = 2) ("Jacksonville" = 1)
("Little Rock" = 4) ("Los Angeles" = 5) ("Miami" = 1) ("Milwaukee" = 2) ("New Hampshire" = 3) ("New Orleans" = 4) ("New York" = 3) ("Orlando" = 1) ("Philadelphia" = 1)
("Rhode Island" = 3) ("Sacramento" = 5) ("San Antonio" = 4) ("San Jose" = 5) ("Seattle" = 5) ("Tulsa" = 4) ("Washington, DC" = 1) (ELSE = SYSMIS) INTO RegionID.
VALUE LABELS RegionID 1 "Atlantic"
2 "Midwest"
3 "Northeast"
4 "South"
5 "West".
ALTER TYPE RegionID (F1.0).
EXECUTE.

ALTER TYPE IALIT IAMTH IAATT IABEH TotalDosage.ATT TotalDosage.BEH TotalDosage.LIT TotalDosage.MTH TotalDosage.OTH LITEnroll ATTEnroll MTHEnroll
BEHEnroll OTHEnroll DN_SCHOOL_BY_GRADE TEAMELAQ2DoseGoalMin TEAMELAQ3DoseGoalMin TEAMELAQ4DoseGoalMin TEAMMTHQ2DoseGoalMin
TEAMMTHQ3DoseGoalMin TEAMMTHQ4DoseGoalMin TEAMELAQ2EnrollBench TEAMMTHQ2EnrollBench TEAMATTQ2EnrollBench TEAMBEHQ2EnrollBench
TEAMELAQ3EnrollBench TEAMMTHQ3EnrollBench TEAMATTQ3EnrollBench TEAMBEHQ3EnrollBench TEAMELADoseBench TEAMMTHDoseBench
TEAMATTDoseBench TEAMBEHDoseBench grdtemp id SITEELAQ2DoseGoalMin SITEELAQ3DoseGoalMin SITEELAQ4DoseGoalMin SITEMTHQ2DoseGoalMin
SITEMTHQ3DoseGoalMin SITEMTHQ4DoseGoalMin SITEELAQ2EnrollBench SITEMTHQ2EnrollBench SITEATTQ2EnrollBench SITEBEHQ2EnrollBench
SITEELAQ3EnrollBench SITEMTHQ3EnrollBench SITEATTQ3EnrollBench SITEBEHQ3EnrollBench ACED2StEngGoal ATT_PRE_SCHOOL_OPEN
ATT_PRE_MISSING ATT_PRE_NOT_ENROLLED ATT_POST_SCHOOL_OPEN ATT_POST_MISSING ATT_POST_NOT_ENROLLED ATT_INC_BY_2_PERC_PT
ATT_IOG_LT_90_TO_GTE LITMet30EnrollALL MTHMet30EnrollALL ATTMet30EnrollALL BEHMet30EnrollALL LITMet30Enroll MTHMet30Enroll ATTMet30Enroll
BEHMet30Enroll ATTMet56Dose BEHMet56Dose LITMetQ2Dose MTHMetQ2Dose LITMetQ3Dose MTHMetQ3Dose LITMetQ4Dose MTHMetQ4Dose IOGGradeCount
LITAssess_anyRawDP LITAssess_2PerfLvlDP LITAssess_StartOffSlid LITAssess_SOSMoveOn IOG_LITAssess35_anyRawDP IOG_LITAssess35_2PerfLvlDP
IOG_LITAssess35_StartOffSlid IOG_LITAssess35_SOSMoveOn IOG_LITAssess69_anyRawDP IOG_LITAssess69_2PerfLvlDP IOG_LITAssess69_StartOffSlid
IOG_LITAssess69_SOSMoveOn ELACG_anyRawDP ELACG_2PerfLvlDP ELACG_StartOffSlid ELACG_SOSMoveOn IOG_ELACG69_anyRawDP
IOG_ELACG69_2PerfLvlDP IOG_ELACG69_StartOffSlid IOG_ELACG69_SOSMoveOn MTHAssess_anyRawDP MTHAssess_2PerfLvlDP MTHAssess_StartOffSlid
MTHAssess_SOSMoveOn IOG_MTHAssess35_anyRawDP IOG_MTHAssess35_2PerfLvlDP IOG_MTHAssess35_StartOffSlid IOG_MTHAssess35_SOSMoveOn
IOG_MTHAssess69_anyRawDP IOG_MTHAssess69_2PerfLvlDP IOG_MTHAssess69_StartOffSlid IOG_MTHAssess69_SOSMoveOn MTHCG_anyRawDP
MTHCG_2PerfLvlDP MTHCG_StartOffSlid MTHCG_SOSMoveOn IOG_MTHCG69_anyRawDP IOG_MTHCG69_2PerfLvlDP IOG_MTHCG69_StartOffSlid
IOG_MTHCG69_SOSMoveOn ATT_anyRawDP ATT_2PerfLvlDP ATT_StartLT90ADA ATT_SOSMoveOn IOG_ATT69_anyRawDP IOG_ATT69_2PerfLvlDP
IOG_ATT69_StartLT90ADA IOG_ATT69_SOSMoveOn ACLITMet30Enroll ACMTHMet30Enroll ACLITorMTHMet30Enroll ACLITMetQ4Dose ACMTHMetQ4Dose
ACLITorMTHMetQ4Dose ACATTMet30Enroll ACBEHMet30Enroll ACATTorBEHMet30Enroll ACATTMet56Dose ACBEHMet56Dose ACATTorBEHMet56Dose
ACStudentGrade (F40.0).

************************************************************************************************************************************************************************************
***** Create team-level summary dataset.
************************************************************************************************************************************************************************************

DATASET DECLARE FINALTEAMDATASET.
DATASET ACTIVATE FINALDATASET.
DATASET COPY FINALFILTERED.
DATASET ACTIVATE FINALFILTERED.
SELECT IF IOGGradeCount = 1.
EXECUTE.

SORT CASES BY Location (A) School (A).
EXECUTE.

AGGREGATE /OUTFILE = FINALTEAMDATASET
   /BREAK = Location School
   /RegionID = MEAN(RegionID)
   /cyStudentIDCount = NU(cyStudentID)
   /cyschSchoolRefID = FIRST(cyschSchoolRefID)
   /cychanSchoolID = FIRST(cychanSchoolID)
   /cysdSiteID = MEAN(cysdSiteID)
   /cysdSchoolID = MEAN(cysdSchoolID)
   /DNSchool = MEAN(DNSchool)
   /MinStudentGrade = MIN(StudentGrade)
   /MaxStudentGrade = MAX(StudentGrade)
   /TotIALIT = SUM(IALIT)
   /TotIAMTH = SUM(IAMTH)
   /TotIAATT = SUM(IAATT)
   /TotIABEH = SUM(IABEH)
   /TEAMIOGMinGrade = MIN(TEAMIOGMinGrade)
   /TEAMIOGMaxGrade = MAX(TEAMIOGMaxGrade)
   /TEAMELAEnrollGoal = MEAN(TEAMELAEnrollGoal)
   /TEAMMTHEnrollGoal = MEAN(TEAMMTHEnrollGoal)
   /TEAMATTEnrollGoal = MEAN(TEAMATTEnrollGoal)
   /TEAMBEHEnrollGoal = MEAN(TEAMBEHEnrollGoal)
   /TEAMELAQ2EnrollBench = MEAN(TEAMELAQ2EnrollBench)
   /TEAMMTHQ2EnrollBench = MEAN(TEAMMTHQ2EnrollBench)
   /TEAMATTQ2EnrollBench = MEAN(TEAMATTQ2EnrollBench)
   /TEAMBEHQ2EnrollBench = MEAN(TEAMBEHQ2EnrollBench)
   /TEAMELAQ3EnrollBench = MEAN(TEAMELAQ3EnrollBench)
   /TEAMMTHQ3EnrollBench = MEAN(TEAMMTHQ3EnrollBench)
   /TEAMATTQ3EnrollBench = MEAN(TEAMATTQ3EnrollBench)
   /TEAMBEHQ3EnrollBench = MEAN(TEAMBEHQ3EnrollBench)
   /TEAMELADoseBench = MEAN(TEAMELADoseBench)
   /TEAMMTHDoseBench = MEAN(TEAMMTHDoseBench)
   /TEAMATTDoseBench = MEAN(TEAMATTDoseBench)
   /TEAMBEHDoseBench = MEAN(TEAMBEHDoseBench)
   /TEAMELAQ2DoseGoal = MEAN(TEAMELAQ2DoseGoal)
   /TEAMELAQ3DoseGoal = MEAN(TEAMELAQ3DoseGoal)
   /TEAMELAQ4DoseGoal = MEAN(TEAMELAQ4DoseGoal)
   /TEAMMTHQ2DoseGoal = MEAN(TEAMMTHQ2DoseGoal)
   /TEAMMTHQ3DoseGoal = MEAN(TEAMMTHQ3DoseGoal)
   /TEAMMTHQ4DoseGoal = MEAN(TEAMMTHQ4DoseGoal)
   /LITMet30Enroll = SUM(LITMet30Enroll)
   /MTHMet30Enroll = SUM(MTHMet30Enroll)
   /ATTMet30Enroll = SUM(ATTMet30Enroll)
   /BEHMet30Enroll = SUM(BEHMet30Enroll)
   /LITMetQ2Dose = SUM(LITMetQ2Dose)
   /LITMetQ3Dose = SUM(LITMetQ3Dose)
   /LITMetQ4Dose = SUM(LITMetQ4Dose)
   /MTHMetQ2Dose = SUM(MTHMetQ2Dose)
   /MTHMetQ3Dose = SUM(MTHMetQ3Dose)
   /MTHMetQ4Dose = SUM(MTHMetQ4Dose)
   /ATTMet56Dose = SUM(ATTMet56Dose)
   /BEHMet56Dose = SUM(BEHMet56Dose)
   /IOG_LIT35_OfficialFL = SUM(IOG_LIT35_OfficialFL)
   /IOG_LIT69_OfficialFL = SUM(IOG_LIT69_OfficialFL)
   /IOG_MTH35_OfficialFL = SUM(IOG_MTH35_OfficialFL)
   /IOG_MTH69_OfficialFL = SUM(IOG_MTH69_OfficialFL)
   /IOG_ATT35_OfficialFL = SUM(IOG_ATT35_OfficialFL)
   /IOG_ATT69_OfficialFL = SUM(IOG_ATT69_OfficialFL)
   /IOG_BEH35_OfficialFL = SUM(IOG_BEH35_OfficialFL)
   /IOG_BEH69_OfficialFL = SUM(IOG_BEH69_OfficialFL)
   /LITAssess_anyRawDP = SUM(LITAssess_anyRawDP)
   /LITAssess_2PerfLvlDP = SUM(LITAssess_2PerfLvlDP)
   /LITAssess_StartOffSlid = SUM(LITAssess_StartOffSlid)
   /LITAssess_SOSMoveOn = SUM(LITAssess_SOSMoveOn)
   /IOG_LITAssess35_anyRawDP = SUM(IOG_LITAssess35_anyRawDP)
   /IOG_LITAssess35_2PerfLvlDP = SUM(IOG_LITAssess35_2PerfLvlDP)
   /IOG_LITAssess35_StartOffSlid = SUM(IOG_LITAssess35_StartOffSlid)
   /IOG_LITAssess35_SOSMoveOn = SUM(IOG_LITAssess35_SOSMoveOn)
   /IOG_LITAssess69_anyRawDP = SUM(IOG_LITAssess69_anyRawDP)
   /IOG_LITAssess69_2PerfLvlDP = SUM(IOG_LITAssess69_2PerfLvlDP)
   /IOG_LITAssess69_StartOffSlid = SUM(IOG_LITAssess69_StartOffSlid)
   /IOG_LITAssess69_SOSMoveOn = SUM(IOG_LITAssess69_SOSMoveOn)
   /BOCY_LITAssess35_StartOffSlid = SUM(BOCY_LITAssess35_StartOffSlid)
   /BOCY_LITAssess69_StartOffSlid = SUM(BOCY_LITAssess69_StartOffSlid)
   /ELACG_anyRawDP = SUM(ELACG_anyRawDP)
   /ELACG_2PerfLvlDP = SUM(ELACG_2PerfLvlDP)
   /ELACG_StartOffSlid = SUM(ELACG_StartOffSlid)
   /ELACG_SOSMoveOn = SUM(ELACG_SOSMoveOn)
   /IOG_ELACG69_anyRawDP = SUM(IOG_ELACG69_anyRawDP)
   /IOG_ELACG69_2PerfLvlDP = SUM(IOG_ELACG69_2PerfLvlDP)
   /IOG_ELACG69_StartOffSlid = SUM(IOG_ELACG69_StartOffSlid)
   /IOG_ELACG69_SOSMoveOn = SUM(IOG_ELACG69_SOSMoveOn)
   /MTHAssess_anyRawDP = SUM(MTHAssess_anyRawDP)
   /MTHAssess_2PerfLvlDP = SUM(MTHAssess_2PerfLvlDP)
   /MTHAssess_StartOffSlid = SUM(MTHAssess_StartOffSlid)
   /MTHAssess_SOSMoveOn = SUM(MTHAssess_SOSMoveOn)
   /IOG_MTHAssess35_anyRawDP = SUM(IOG_MTHAssess35_anyRawDP)
   /IOG_MTHAssess35_2PerfLvlDP = SUM(IOG_MTHAssess35_2PerfLvlDP)
   /IOG_MTHAssess35_StartOffSlid = SUM(IOG_MTHAssess35_StartOffSlid)
   /IOG_MTHAssess35_SOSMoveOn = SUM(IOG_MTHAssess35_SOSMoveOn)
   /IOG_MTHAssess69_anyRawDP = SUM(IOG_MTHAssess69_anyRawDP)
   /IOG_MTHAssess69_2PerfLvlDP = SUM(IOG_MTHAssess69_2PerfLvlDP)
   /IOG_MTHAssess69_StartOffSlid = SUM(IOG_MTHAssess69_StartOffSlid)
   /IOG_MTHAssess69_SOSMoveOn = SUM(IOG_MTHAssess69_SOSMoveOn)
   /BOCY_MTHAssess35_StartOffSlid = SUM(BOCY_MTHAssess35_StartOffSlid)
   /BOCY_MTHAssess69_StartOffSlid = SUM(BOCY_MTHAssess69_StartOffSlid)
   /MTHCG_anyRawDP = SUM(MTHCG_anyRawDP)
   /MTHCG_2PerfLvlDP = SUM(MTHCG_2PerfLvlDP)
   /MTHCG_StartOffSlid = SUM(MTHCG_StartOffSlid)
   /MTHCG_SOSMoveOn = SUM(MTHCG_SOSMoveOn)
   /IOG_MTHCG69_anyRawDP = SUM(IOG_MTHCG69_anyRawDP)
   /IOG_MTHCG69_2PerfLvlDP = SUM(IOG_MTHCG69_2PerfLvlDP)
   /IOG_MTHCG69_StartOffSlid = SUM(IOG_MTHCG69_StartOffSlid)
   /IOG_MTHCG69_SOSMoveOn = SUM(IOG_MTHCG69_SOSMoveOn)
   /ATT_anyRawDP = SUM(ATT_anyRawDP)
   /ATT_2PerfLvlDP = SUM(ATT_2PerfLvlDP)
   /ATT_StartLT90ADA = SUM(ATT_StartLT90ADA)
   /ATT_SOSMoveOn = SUM(ATT_SOSMoveOn)
   /IOG_ATT69_anyRawDP = SUM(IOG_ATT69_anyRawDP)
   /IOG_ATT69_2PerfLvlDP = SUM(IOG_ATT69_2PerfLvlDP)
   /IOG_ATT69_StartLT90ADA = SUM(IOG_ATT69_StartLT90ADA)
   /IOG_ATT69_SOSMoveOn = SUM(IOG_ATT69_SOSMoveOn)
   /BOCY_ATT69_StartLT90ADA = SUM(BOCY_ATT69_StartLT90ADA).

DATASET ACTIVATE FINALTEAMDATASET.

***** Calculate % met dosage variables and % met IOG.
COMPUTE LITMetQ4DosePerc = LITMetQ4Dose / LITMet30Enroll.
COMPUTE MTHMetQ4DosePerc = MTHMetQ4Dose / MTHMet30Enroll.
COMPUTE ATTMet56DosePerc = ATTMet56Dose / ATTMet30Enroll.
COMPUTE BEHMet56DosePerc = BEHMet56Dose / BEHMet30Enroll.
COMPUTE IOG_LITAssess35_SOSMoveOnPerc = IOG_LITAssess35_SOSMoveOn / IOG_LITAssess35_StartOffSlid.
COMPUTE IOG_LITAssess69_SOSMoveOnPerc = IOG_LITAssess69_SOSMoveOn / IOG_LITAssess69_StartOffSlid.
COMPUTE IOG_ELACG69_SOSMoveOnPerc = IOG_ELACG69_SOSMoveOn / IOG_ELACG69_StartOffSlid.
COMPUTE IOG_MTHAssess35_SOSMoveOnPerc = IOG_MTHAssess35_SOSMoveOn / IOG_MTHAssess35_StartOffSlid.
COMPUTE IOG_MTHAssess69_SOSMoveOnPerc = IOG_MTHAssess69_SOSMoveOn / IOG_MTHAssess69_StartOffSlid.
COMPUTE IOG_MTHCG69_SOSMoveOnPerc = IOG_MTHCG69_SOSMoveOn / IOG_MTHCG69_StartOffSlid.
COMPUTE IOG_ATT69_SOSMoveOnPerc = IOG_ATT69_SOSMoveOn / IOG_ATT69_StartLT90ADA.
EXECUTE.

ALTER TYPE RegionID cysdSiteID cysdSchoolID DNSchool TotIALIT TotIAMTH TotIAATT TotIABEH TEAMELAEnrollGoal TEAMMTHEnrollGoal TEAMATTEnrollGoal
TEAMBEHEnrollGoal TEAMELAQ2EnrollBench TEAMMTHQ2EnrollBench TEAMATTQ2EnrollBench TEAMBEHQ2EnrollBench TEAMELAQ3EnrollBench
TEAMMTHQ3EnrollBench TEAMATTQ3EnrollBench TEAMBEHQ3EnrollBench TEAMELADoseBench TEAMMTHDoseBench TEAMATTDoseBench
TEAMBEHDoseBench TEAMELAQ2DoseGoal TEAMELAQ3DoseGoal TEAMELAQ4DoseGoal TEAMMTHQ2DoseGoal TEAMMTHQ3DoseGoal TEAMMTHQ4DoseGoal
LITMet30Enroll MTHMet30Enroll ATTMet30Enroll BEHMet30Enroll LITMetQ2Dose LITMetQ3Dose LITMetQ4Dose MTHMetQ2Dose MTHMetQ3Dose MTHMetQ4Dose
ATTMet56Dose BEHMet56Dose LITAssess_anyRawDP LITAssess_2PerfLvlDP LITAssess_StartOffSlid LITAssess_SOSMoveOn IOG_LITAssess35_anyRawDP
IOG_LITAssess35_2PerfLvlDP IOG_LITAssess35_StartOffSlid IOG_LITAssess35_SOSMoveOn IOG_LITAssess69_anyRawDP IOG_LITAssess69_2PerfLvlDP
IOG_LITAssess69_StartOffSlid IOG_LITAssess69_SOSMoveOn ELACG_anyRawDP ELACG_2PerfLvlDP ELACG_StartOffSlid ELACG_SOSMoveOn
IOG_ELACG69_anyRawDP IOG_ELACG69_2PerfLvlDP IOG_ELACG69_StartOffSlid IOG_ELACG69_SOSMoveOn MTHAssess_anyRawDP MTHAssess_2PerfLvlDP
MTHAssess_StartOffSlid MTHAssess_SOSMoveOn IOG_MTHAssess35_anyRawDP IOG_MTHAssess35_2PerfLvlDP IOG_MTHAssess35_StartOffSlid
IOG_MTHAssess35_SOSMoveOn IOG_MTHAssess69_anyRawDP IOG_MTHAssess69_2PerfLvlDP IOG_MTHAssess69_StartOffSlid IOG_MTHAssess69_SOSMoveOn
MTHCG_anyRawDP MTHCG_2PerfLvlDP MTHCG_StartOffSlid MTHCG_SOSMoveOn IOG_MTHCG69_anyRawDP IOG_MTHCG69_2PerfLvlDP
IOG_MTHCG69_StartOffSlid IOG_MTHCG69_SOSMoveOn ATT_anyRawDP ATT_2PerfLvlDP ATT_StartLT90ADA ATT_SOSMoveOn IOG_ATT69_anyRawDP
IOG_ATT69_2PerfLvlDP IOG_ATT69_StartLT90ADA IOG_ATT69_SOSMoveOn (F40.0) LITMetQ4DosePerc MTHMetQ4DosePerc ATTMet56DosePerc BEHMet56DosePerc
IOG_LITAssess35_SOSMoveOnPerc IOG_LITAssess69_SOSMoveOnPerc IOG_ELACG69_SOSMoveOnPerc IOG_MTHAssess35_SOSMoveOnPerc
IOG_MTHAssess69_SOSMoveOnPerc IOG_MTHCG69_SOSMoveOnPerc IOG_ATT69_SOSMoveOnPerc (F40.3).

***** Add variable labels.
VARIABLE LABELS cyStudentIDCount "Total number of student records"
   DNSchool "Diplomas Now Schools"
   MinStudentGrade "Lowest grade level in dataset"
   MaxStudentGrade "Highest grade level in dataset"
   TotIALIT "Number of students with a literacy IA-assignment"
   TotIAMTH "Number of students with a math IA-assignment"
   TotIAATT "Number of students with an attendance IA-assignment"
   TotIABEH "Number of students with a behavior IA-assignment"
   TEAMIOGMinGrade "Lowest grade level specified for internal reporting purposes"
   TEAMIOGMaxGrade "Highest grade level specified for internal reporting purposes"
   TEAMELAEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 ELA/Literacy Focus List"
   TEAMMTHEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 Math Focus List"
   TEAMATTEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 Attendance Focus List"
   TEAMBEHEnrollGoal "ENROLL GOAL (EOY)\nTeam-Level FY14 Behavior Focus List"
   TEAMELAQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level ELA/Literacy Enrollment"
   TEAMMTHQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level Math Enrollment"
   TEAMATTQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level Attendance Enrollment"
   TEAMBEHQ2EnrollBench "ENROLL GOAL (Q2)\nTeam-Level Behavior Enrollment"
   TEAMELAQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level ELA/Literacy Enrollment"
   TEAMMTHQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level Math Enrollment"
   TEAMATTQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level Attendance Enrollment"
   TEAMBEHQ3EnrollBench "ENROLL GOAL (Q3)\nTeam-Level Behavior Enrollment"
   TEAMELADoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level ELA/Literacy Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMMTHDoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level Math Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMATTDoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level Attendance Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMBEHDoseBench "DOSAGE GOAL (EOY)\nFY14 Team-Level Behavior Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMELAQ2DoseGoal "DOSAGE GOAL (Q2)\nTeam-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ3DoseGoal "DOSAGE GOAL (Q3)\nTeam-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ4DoseGoal "DOSAGE GOAL (Q4)\nTeam-Level ELA/Literacy Per-Student (in hours)"
   TEAMMTHQ2DoseGoal "DOSAGE GOAL (Q2)\nTeam-Level Math Per-Student (in hours)"
   TEAMMTHQ3DoseGoal "DOSAGE GOAL (Q3)\nTeam-Level Math Per-Student (in hours)"
   TEAMMTHQ4DoseGoal "DOSAGE GOAL (Q4)\nTeam-Level Math Per-Student (in hours)"
   LITMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (ELA/Literacy, with overlap)"
   MTHMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Math, with overlap)"
   ATTMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Attendance, with overlap)"
   BEHMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Behavior, with overlap)"
   LITMetQ2Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q2 Dosage Benchmark (with overlap)"
   LITMetQ3Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q3 Dosage Benchmark (with overlap)"
   LITMetQ4Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q4 Dosage Benchmark (with overlap)"
   MTHMetQ2Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q2 Dosage Benchmark (with overlap)"
   MTHMetQ3Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q3 Dosage Benchmark (with overlap)"
   MTHMetQ4Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q4 Dosage Benchmark (with overlap)"
   ATTMet56Dose "DOSAGE ACTUAL\nNumber of Students Enrolled 56+ Days (Attendance, with overlap)"
   BEHMet56Dose "DOSAGE ACTUAL\nNumber of Students Enrolled 56+ Days (Behavior, with overlap)"
   IOG_LIT35_OfficialFL "IOG: 3rd-5th Grade Literacy: Number of students on official focus lists"
   IOG_LIT69_OfficialFL "IOG: 6th-9th Grade Literacy: Number of students on official focus lists"
   IOG_MTH35_OfficialFL "IOG: 3rd-5th Grade Math: Number of students on official focus lists"
   IOG_MTH69_OfficialFL "IOG: 6th-9th Grade Math: Number of students on official focus lists"
   IOG_ATT35_OfficialFL "IOG: 3rd-5th Grade Attendance: Number of students on official focus lists"
   IOG_ATT69_OfficialFL "IOG: 6th-9th Grade Attendance: Number of students on official focus lists"
   IOG_BEH35_OfficialFL "IOG: 3rd-5th Grade Behavior: Number of students on official focus lists"
   IOG_BEH69_OfficialFL "IOG: 6th-9th Grade Bheavior: Number of students on official focus lists"
   LITAssess_anyRawDP "Number of students with at least one raw literacy assessment performance data point"
   LITAssess_2PerfLvlDP "Number of students with at least two literacy assessment performance level data points"
   LITAssess_StartOffSlid "Number of students who started off-track or sliding in literacy assessments"
   LITAssess_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in literacy assessments"
   IOG_LITAssess35_anyRawDP "IOG: 3rd-5th Grade Literacy Assessments: Number of students who had at least one raw performance data point"
   IOG_LITAssess35_2PerfLvlDP "IOG: 3rd-5th Grade Literacy Assessments: Number of students who had at least two performance level data points"
   IOG_LITAssess35_StartOffSlid "IOG: 3rd-5th Grade Literacy Assessments: Number of students who started off-track or sliding"
   IOG_LITAssess35_SOSMoveOn "IOG: 3rd-5th Grade Literacy Assessments: Number of students who started off-track or sliding and moved back on-track"
   IOG_LITAssess69_anyRawDP "IOG: 6th-9th Grade Literacy Assessments: Number of students who had at least one raw performance data point"
   IOG_LITAssess69_2PerfLvlDP "IOG: 6th-9th Grade Literacy Assessments: Number of students who had at least two performance level data points"
   IOG_LITAssess69_StartOffSlid "IOG: 6th-9th Grade Literacy Assessments: Number of students who started off-track or sliding"
   IOG_LITAssess69_SOSMoveOn "IOG: 6th-9th Grade Literacy Assessments: Number of students who started off-track or sliding and moved back on-track"
   BOCY_LITAssess35_StartOffSlid "Best of City Year: 3rd-5th Grade Literacy Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   BOCY_LITAssess69_StartOffSlid "Best of City Year: 6th-9th Grade Literacy Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   ELACG_anyRawDP "Number of students with at least one ELA course grade performance data point"
   ELACG_2PerfLvlDP "Number of students with at least two ELA course grade performance level data points"
   ELACG_StartOffSlid "Number of students who started off-track or sliding in ELA course grades"
   ELACG_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in ELA course grades"
   IOG_ELACG69_anyRawDP "IOG: 6th-9th Grade ELA Course Grades: Number of students who had at least one course grade performance data point"
   IOG_ELACG69_2PerfLvlDP "IOG: 6th-9th Grade ELA Course Grades: Number of students who had at least two performance level data points"
   IOG_ELACG69_StartOffSlid "IOG: 6th-9th Grade ELA Course Grades: Number of students who started off-track or sliding"
   IOG_ELACG69_SOSMoveOn "IOG: 6th-9th Grade ELA Course Grades: Number of students who started off-track or sliding and moved back on-track"
   MTHAssess_anyRawDP "Number of students with at least one raw math assessment performance data point"
   MTHAssess_2PerfLvlDP "Number of students with at least two math assessment performance level data points"
   MTHAssess_StartOffSlid "Number of students who started off-track or sliding in math assessments"
   MTHAssess_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in math assessments"
   IOG_MTHAssess35_anyRawDP "IOG: 3rd-5th Grade Math Assessments: Number of students who had at least one raw performance data point"
   IOG_MTHAssess35_2PerfLvlDP "IOG: 3rd-5th Grade Math Assessments: Number of students who had at least two performance level data points"
   IOG_MTHAssess35_StartOffSlid "IOG: 3rd-5th Grade Math Assessments: Number of students who started off-track or sliding"
   IOG_MTHAssess35_SOSMoveOn "IOG: 3rd-5th Grade Math Assessments: Number of students who started off-track or sliding and moved back on-track"
   IOG_MTHAssess69_anyRawDP "IOG: 6th-9th Grade Math Assessments: Number of students who had at least one raw performance data point"
   IOG_MTHAssess69_2PerfLvlDP "IOG: 6th-9th Grade Math Assessments: Number of students who had at least two performance level data points"
   IOG_MTHAssess69_StartOffSlid "IOG: 6th-9th Grade Math Assessments: Number of students who started off-track or sliding"
   IOG_MTHAssess69_SOSMoveOn "IOG: 6th-9th Grade Math Assessments: Number of students who started off-track or sliding and moved back on-track"
   BOCY_MTHAssess35_StartOffSlid "Best of City Year: 3rd-5th Grade Math Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   BOCY_MTHAssess69_StartOffSlid "Best of City Year: 6th-9th Grade Math Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   MTHCG_anyRawDP "Number of students with at least one math course grade performance data point"
   MTHCG_2PerfLvlDP "Number of students with at least two math course grade performance level data points"
   MTHCG_StartOffSlid "Number of students who started off-track or sliding in math course grades"
   MTHCG_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in math course grades"
   IOG_MTHCG69_anyRawDP "IOG: 6th-9th Grade Math Course Grades: Number of students who had at least one course grade performance data point"
   IOG_MTHCG69_2PerfLvlDP "IOG: 6th-9th Grade Math Course Grades: Number of students who had at least two performance level data points"
   IOG_MTHCG69_StartOffSlid "IOG: 6th-9th Grade Math Course Grades: Number of students who started off-track or sliding"
   IOG_MTHCG69_SOSMoveOn "IOG: 6th-9th Grade Math Course Grades: Number of students who started off-track or sliding and moved back on-track"
   ATT_anyRawDP "Number of students with at least one attendance (ADA) performance data point"
   ATT_2PerfLvlDP "Number of students with at least two attendance (ADA) performance level data points"
   ATT_StartLT90ADA "Number of students who started with less than 90% average daily attendance"
   ATT_SOSMoveOn "Number of students who started below 90% ADA and moved to at or above 90% ADA"
   IOG_ATT69_anyRawDP "IOG: 6th-9th Grade Attendance: Number of students who had at least one ADA performance data point"
   IOG_ATT69_2PerfLvlDP "IOG: 6th-9th Grade Attendance: Number of students who had at least two performance level data points"
   IOG_ATT69_StartLT90ADA "IOG: 6th-9th Grade Attendance: Number of students who started with less than 90% average daily attendance"
   IOG_ATT69_SOSMoveOn "IOG: 6th-9th Grade Attendance: Number of students who started below 90% ADA and moved to at or above 90% ADA"
   BOCY_ATT69_StartLT90ADA "Best of City Year: 6th-9th Grade Attendance: Number of students on official focus lists, enrolled 56+ days, and started with less than 90% average daily attendance"
   LITMetQ4DosePerc "DOSAGE ACTUAL\n% of Students Meeting ELA/Literacy Q4 Dosage Benchmark (out of ACTUAL FL Enrollment)"
   MTHMetQ4DosePerc "DOSAGE ACTUAL\n% of Students Meeting Math Q4 Dosage Benchmark (out of ACTUAL FL Enrollment)"
   ATTMet56DosePerc "DOSAGE ACTUAL\n% of Students Enrolled 56+ Days (Attendance, out of ACTUAL FL Enrollment)"
   BEHMet56DosePerc "DOSAGE ACTUAL\n% of Students Enrolled 56+ Days (Behavior, out of ACTUAL FL Enrollment)"
   IOG_LITAssess35_SOSMoveOnPerc "IOG ACTUAL\n3rd-5th Grade Literacy: % of Students who Moved from Below Benchmark on Literacy Skills Assessments to At/Above Benchmark"
   IOG_LITAssess69_SOSMoveOnPerc "IOG ACTUAL\n6th-9th Grade Literacy: % of Students who Moved from Below Benchmark on Literacy Skills Assessments to At/Above Benhcmark"
   IOG_ELACG69_SOSMoveOnPerc 'IOG ACTUAL\n6th-9th Grade ELA: % of Students who Moved from an ELA Course Grade of "D" or Lower to a "C" or Higher'
   IOG_MTHAssess35_SOSMoveOnPerc "IOG ACTUAL\n3rd-5th Grade Math: % of Students who Moved from Below Benchmark on Math Skills Assessments to At/Above Benchmark"
   IOG_MTHAssess69_SOSMoveOnPerc "IOG ACTUAL\n6th-9th Grade Math: % of Students who Moved from Below Benchmark on Math Skills Assessments to At/Above Benchmark"
   IOG_MTHCG69_SOSMoveOnPerc 'IOG ACTUAL\n6th-9th Grade Math: % of Students who Moved from a Math Course Grade of "D" or Lower to a "C" or Higher'
   IOG_ATT69_SOSMoveOnPerc "IOG ACTUAL\n6th-9th Grade Attendance: % of Students who Moved from Below 90% ADA to At/Above 90% ADA".

VALUE LABELS DNSchool 0 "Not a Diplomas Now School"
   1 "Diplomas Now School".
VALUE LABELS RegionID 1 "Atlantic"
2 "Midwest"
3 "Northeast"
4 "South"
5 "West".
EXECUTE.

***** No longer need filtered dataset.
DATASET CLOSE FINALFILTERED.

************************************************************************************************************************************************************************************
***** Create site-level summary dataset.
************************************************************************************************************************************************************************************

DATASET DECLARE FINALSITEDATASET.
DATASET ACTIVATE FINALTEAMDATASET.
DATASET COPY TEAMAGG.
DATASET ACTIVATE TEAMAGG.

AGGREGATE /OUTFILE = FINALSITEDATASET
   /BREAK = Location
   /RegionID = MEAN(RegionID)
   /cyStudentIDCount = SUM(cyStudentIDCount)
   /schoolCount = NU(cyschSchoolRefID)
   /cysdSiteID = MEAN(cysdSiteID)
   /DNSchoolCount = SUM(DNSchool)
   /MinStudentGrade = MIN(MinStudentGrade)
   /MaxStudentGrade = MAX(MaxStudentGrade)
   /TotIALIT = SUM(TotIALIT)
   /TotIAMTH = SUM(TotIAMTH)
   /TotIAATT = SUM(TotIAATT)
   /TotIABEH = SUM(TotIABEH)
   /TEAMIOGMinGrade = MIN(TEAMIOGMinGrade)
   /TEAMIOGMaxGrade = MAX(TEAMIOGMaxGrade)
   /SITEELAEnrollGoal = SUM(TEAMELAEnrollGoal)
   /SITEMTHEnrollGoal = SUM(TEAMMTHEnrollGoal)
   /SITEATTEnrollGoal = SUM(TEAMATTEnrollGoal)
   /SITEBEHEnrollGoal = SUM(TEAMBEHEnrollGoal)
   /SITEELAQ2EnrollBench = SUM(TEAMELAQ2EnrollBench)
   /SITEMTHQ2EnrollBench = SUM(TEAMMTHQ2EnrollBench)
   /SITEATTQ2EnrollBench = SUM(TEAMATTQ2EnrollBench)
   /SITEBEHQ2EnrollBench = SUM(TEAMBEHQ2EnrollBench)
   /SITEELAQ3EnrollBench = SUM(TEAMELAQ3EnrollBench)
   /SITEMTHQ3EnrollBench = SUM(TEAMMTHQ3EnrollBench)
   /SITEATTQ3EnrollBench = SUM(TEAMATTQ3EnrollBench)
   /SITEBEHQ3EnrollBench = SUM(TEAMBEHQ3EnrollBench)
   /SITEELADoseBench = SUM(TEAMELADoseBench)
   /SITEMTHDoseBench = SUM(TEAMMTHDoseBench)
   /SITEATTDoseBench = SUM(TEAMATTDoseBench)
   /SITEBEHDoseBench = SUM(TEAMBEHDoseBench)
   /TEAMELAQ2DoseGoalMin = MIN(TEAMELAQ2DoseGoal)
   /TEAMELAQ3DoseGoalMin = MIN(TEAMELAQ3DoseGoal)
   /TEAMELAQ4DoseGoalMin = MIN(TEAMELAQ4DoseGoal)
   /TEAMELAQ2DoseGoalMax = MAX(TEAMELAQ2DoseGoal)
   /TEAMELAQ3DoseGoalMax = MAX(TEAMELAQ3DoseGoal)
   /TEAMELAQ4DoseGoalMax = MAX(TEAMELAQ4DoseGoal)
   /TEAMMTHQ2DoseGoalMin = MIN(TEAMMTHQ2DoseGoal)
   /TEAMMTHQ3DoseGoalMin = MIN(TEAMMTHQ3DoseGoal)
   /TEAMMTHQ4DoseGoalMin = MIN(TEAMMTHQ4DoseGoal)
   /TEAMMTHQ2DoseGoalMax = MAX(TEAMMTHQ2DoseGoal)
   /TEAMMTHQ3DoseGoalMax = MAX(TEAMMTHQ3DoseGoal)
   /TEAMMTHQ4DoseGoalMax = MAX(TEAMMTHQ4DoseGoal)
   /LITMet30Enroll = SUM(LITMet30Enroll)
   /MTHMet30Enroll = SUM(MTHMet30Enroll)
   /ATTMet30Enroll = SUM(ATTMet30Enroll)
   /BEHMet30Enroll = SUM(BEHMet30Enroll)
   /LITMetQ2Dose = SUM(LITMetQ2Dose)
   /LITMetQ3Dose = SUM(LITMetQ3Dose)
   /LITMetQ4Dose = SUM(LITMetQ4Dose)
   /MTHMetQ2Dose = SUM(MTHMetQ2Dose)
   /MTHMetQ3Dose = SUM(MTHMetQ3Dose)
   /MTHMetQ4Dose = SUM(MTHMetQ4Dose)
   /ATTMet56Dose = SUM(ATTMet56Dose)
   /BEHMet56Dose = SUM(BEHMet56Dose)
   /IOG_LIT35_OfficialFL = SUM(IOG_LIT35_OfficialFL)
   /IOG_LIT69_OfficialFL = SUM(IOG_LIT69_OfficialFL)
   /IOG_MTH35_OfficialFL = SUM(IOG_MTH35_OfficialFL)
   /IOG_MTH69_OfficialFL = SUM(IOG_MTH69_OfficialFL)
   /IOG_ATT35_OfficialFL = SUM(IOG_ATT35_OfficialFL)
   /IOG_ATT69_OfficialFL = SUM(IOG_ATT69_OfficialFL)
   /IOG_BEH35_OfficialFL = SUM(IOG_BEH35_OfficialFL)
   /IOG_BEH69_OfficialFL = SUM(IOG_BEH69_OfficialFL)
   /LITAssess_anyRawDP = SUM(LITAssess_anyRawDP)
   /LITAssess_2PerfLvlDP = SUM(LITAssess_2PerfLvlDP)
   /LITAssess_StartOffSlid = SUM(LITAssess_StartOffSlid)
   /LITAssess_SOSMoveOn = SUM(LITAssess_SOSMoveOn)
   /IOG_LITAssess35_anyRawDP = SUM(IOG_LITAssess35_anyRawDP)
   /IOG_LITAssess35_2PerfLvlDP = SUM(IOG_LITAssess35_2PerfLvlDP)
   /IOG_LITAssess35_StartOffSlid = SUM(IOG_LITAssess35_StartOffSlid)
   /IOG_LITAssess35_SOSMoveOn = SUM(IOG_LITAssess35_SOSMoveOn)
   /IOG_LITAssess69_anyRawDP = SUM(IOG_LITAssess69_anyRawDP)
   /IOG_LITAssess69_2PerfLvlDP = SUM(IOG_LITAssess69_2PerfLvlDP)
   /IOG_LITAssess69_StartOffSlid = SUM(IOG_LITAssess69_StartOffSlid)
   /IOG_LITAssess69_SOSMoveOn = SUM(IOG_LITAssess69_SOSMoveOn)
   /BOCY_LITAssess35_StartOffSlid = SUM(BOCY_LITAssess35_StartOffSlid)
   /BOCY_LITAssess69_StartOffSlid = SUM(BOCY_LITAssess69_StartOffSlid)
   /ELACG_anyRawDP = SUM(ELACG_anyRawDP)
   /ELACG_2PerfLvlDP = SUM(ELACG_2PerfLvlDP)
   /ELACG_StartOffSlid = SUM(ELACG_StartOffSlid)
   /ELACG_SOSMoveOn = SUM(ELACG_SOSMoveOn)
   /IOG_ELACG69_anyRawDP = SUM(IOG_ELACG69_anyRawDP)
   /IOG_ELACG69_2PerfLvlDP = SUM(IOG_ELACG69_2PerfLvlDP)
   /IOG_ELACG69_StartOffSlid = SUM(IOG_ELACG69_StartOffSlid)
   /IOG_ELACG69_SOSMoveOn = SUM(IOG_ELACG69_SOSMoveOn)
   /MTHAssess_anyRawDP = SUM(MTHAssess_anyRawDP)
   /MTHAssess_2PerfLvlDP = SUM(MTHAssess_2PerfLvlDP)
   /MTHAssess_StartOffSlid = SUM(MTHAssess_StartOffSlid)
   /MTHAssess_SOSMoveOn = SUM(MTHAssess_SOSMoveOn)
   /IOG_MTHAssess35_anyRawDP = SUM(IOG_MTHAssess35_anyRawDP)
   /IOG_MTHAssess35_2PerfLvlDP = SUM(IOG_MTHAssess35_2PerfLvlDP)
   /IOG_MTHAssess35_StartOffSlid = SUM(IOG_MTHAssess35_StartOffSlid)
   /IOG_MTHAssess35_SOSMoveOn = SUM(IOG_MTHAssess35_SOSMoveOn)
   /IOG_MTHAssess69_anyRawDP = SUM(IOG_MTHAssess69_anyRawDP)
   /IOG_MTHAssess69_2PerfLvlDP = SUM(IOG_MTHAssess69_2PerfLvlDP)
   /IOG_MTHAssess69_StartOffSlid = SUM(IOG_MTHAssess69_StartOffSlid)
   /IOG_MTHAssess69_SOSMoveOn = SUM(IOG_MTHAssess69_SOSMoveOn)
   /BOCY_MTHAssess35_StartOffSlid = SUM(BOCY_MTHAssess35_StartOffSlid)
   /BOCY_MTHAssess69_StartOffSlid = SUM(BOCY_MTHAssess69_StartOffSlid)
   /MTHCG_anyRawDP = SUM(MTHCG_anyRawDP)
   /MTHCG_2PerfLvlDP = SUM(MTHCG_2PerfLvlDP)
   /MTHCG_StartOffSlid = SUM(MTHCG_StartOffSlid)
   /MTHCG_SOSMoveOn = SUM(MTHCG_SOSMoveOn)
   /IOG_MTHCG69_anyRawDP = SUM(IOG_MTHCG69_anyRawDP)
   /IOG_MTHCG69_2PerfLvlDP = SUM(IOG_MTHCG69_2PerfLvlDP)
   /IOG_MTHCG69_StartOffSlid = SUM(IOG_MTHCG69_StartOffSlid)
   /IOG_MTHCG69_SOSMoveOn = SUM(IOG_MTHCG69_SOSMoveOn)
   /ATT_anyRawDP = SUM(ATT_anyRawDP)
   /ATT_2PerfLvlDP = SUM(ATT_2PerfLvlDP)
   /ATT_StartLT90ADA = SUM(ATT_StartLT90ADA)
   /ATT_SOSMoveOn = SUM(ATT_SOSMoveOn)
   /IOG_ATT69_anyRawDP = SUM(IOG_ATT69_anyRawDP)
   /IOG_ATT69_2PerfLvlDP = SUM(IOG_ATT69_2PerfLvlDP)
   /IOG_ATT69_StartLT90ADA = SUM(IOG_ATT69_StartLT90ADA)
   /IOG_ATT69_SOSMoveOn = SUM(IOG_ATT69_SOSMoveOn)
   /BOCY_ATT69_StartLT90ADA = SUM(BOCY_ATT69_StartLT90ADA).

DATASET ACTIVATE FINALSITEDATASET.

***** Calculate % met dosage variables and % met IOG.
COMPUTE LITMetQ4DosePerc = LITMetQ4Dose / LITMet30Enroll.
COMPUTE MTHMetQ4DosePerc = MTHMetQ4Dose / MTHMet30Enroll.
COMPUTE ATTMet56DosePerc = ATTMet56Dose / ATTMet30Enroll.
COMPUTE BEHMet56DosePerc = BEHMet56Dose / BEHMet30Enroll.
COMPUTE IOG_LITAssess35_SOSMoveOnPerc = IOG_LITAssess35_SOSMoveOn / IOG_LITAssess35_StartOffSlid.
COMPUTE IOG_LITAssess69_SOSMoveOnPerc = IOG_LITAssess69_SOSMoveOn / IOG_LITAssess69_StartOffSlid.
COMPUTE IOG_ELACG69_SOSMoveOnPerc = IOG_ELACG69_SOSMoveOn / IOG_ELACG69_StartOffSlid.
COMPUTE IOG_MTHAssess35_SOSMoveOnPerc = IOG_MTHAssess35_SOSMoveOn / IOG_MTHAssess35_StartOffSlid.
COMPUTE IOG_MTHAssess69_SOSMoveOnPerc = IOG_MTHAssess69_SOSMoveOn / IOG_MTHAssess69_StartOffSlid.
COMPUTE IOG_MTHCG69_SOSMoveOnPerc = IOG_MTHCG69_SOSMoveOn / IOG_MTHCG69_StartOffSlid.
COMPUTE IOG_ATT69_SOSMoveOnPerc = IOG_ATT69_SOSMoveOn / IOG_ATT69_StartLT90ADA.
EXECUTE.

ALTER TYPE RegionID cyStudentIDCount cysdSiteID DNSchoolCount TotIALIT TotIAMTH TotIAATT TotIABEH SITEELAEnrollGoal SITEMTHEnrollGoal
SITEATTEnrollGoal SITEBEHEnrollGoal SITEELAQ2EnrollBench SITEMTHQ2EnrollBench SITEATTQ2EnrollBench SITEBEHQ2EnrollBench SITEELAQ3EnrollBench
SITEMTHQ3EnrollBench SITEATTQ3EnrollBench SITEBEHQ3EnrollBench SITEELADoseBench SITEMTHDoseBench SITEATTDoseBench SITEBEHDoseBench
TEAMELAQ2DoseGoalMin TEAMELAQ3DoseGoalMin TEAMELAQ4DoseGoalMin TEAMELAQ2DoseGoalMax TEAMELAQ3DoseGoalMax TEAMELAQ4DoseGoalMax
TEAMMTHQ2DoseGoalMin TEAMMTHQ3DoseGoalMin TEAMMTHQ4DoseGoalMin TEAMMTHQ2DoseGoalMax TEAMMTHQ3DoseGoalMax TEAMMTHQ4DoseGoalMax
LITMet30Enroll MTHMet30Enroll ATTMet30Enroll BEHMet30Enroll LITMetQ2Dose LITMetQ3Dose LITMetQ4Dose MTHMetQ2Dose MTHMetQ3Dose MTHMetQ4Dose
ATTMet56Dose BEHMet56Dose LITAssess_anyRawDP LITAssess_2PerfLvlDP LITAssess_StartOffSlid LITAssess_SOSMoveOn IOG_LITAssess35_anyRawDP
IOG_LITAssess35_2PerfLvlDP IOG_LITAssess35_StartOffSlid IOG_LITAssess35_SOSMoveOn IOG_LITAssess69_anyRawDP IOG_LITAssess69_2PerfLvlDP
IOG_LITAssess69_StartOffSlid IOG_LITAssess69_SOSMoveOn ELACG_anyRawDP ELACG_2PerfLvlDP ELACG_StartOffSlid ELACG_SOSMoveOn
IOG_ELACG69_anyRawDP IOG_ELACG69_2PerfLvlDP IOG_ELACG69_StartOffSlid IOG_ELACG69_SOSMoveOn MTHAssess_anyRawDP MTHAssess_2PerfLvlDP
MTHAssess_StartOffSlid MTHAssess_SOSMoveOn IOG_MTHAssess35_anyRawDP IOG_MTHAssess35_2PerfLvlDP IOG_MTHAssess35_StartOffSlid
IOG_MTHAssess35_SOSMoveOn IOG_MTHAssess69_anyRawDP IOG_MTHAssess69_2PerfLvlDP IOG_MTHAssess69_StartOffSlid IOG_MTHAssess69_SOSMoveOn
MTHCG_anyRawDP MTHCG_2PerfLvlDP MTHCG_StartOffSlid MTHCG_SOSMoveOn IOG_MTHCG69_anyRawDP IOG_MTHCG69_2PerfLvlDP
IOG_MTHCG69_StartOffSlid IOG_MTHCG69_SOSMoveOn ATT_anyRawDP ATT_2PerfLvlDP ATT_StartLT90ADA ATT_SOSMoveOn IOG_ATT69_anyRawDP
IOG_ATT69_2PerfLvlDP IOG_ATT69_StartLT90ADA IOG_ATT69_SOSMoveOn (F40.0) LITMetQ4DosePerc MTHMetQ4DosePerc ATTMet56DosePerc BEHMet56DosePerc
IOG_LITAssess35_SOSMoveOnPerc IOG_LITAssess69_SOSMoveOnPerc IOG_ELACG69_SOSMoveOnPerc IOG_MTHAssess35_SOSMoveOnPerc
IOG_MTHAssess69_SOSMoveOnPerc IOG_MTHCG69_SOSMoveOnPerc IOG_ATT69_SOSMoveOnPerc (F40.3).

***** Add variable labels.
VARIABLE LABELS cyStudentIDCount "Total number of student records"
   schoolCount "Total number of schools"
   DNSchoolCount "Total number of DN schools"
   MinStudentGrade "Lowest grade level in dataset"
   MaxStudentGrade "Highest grade level in dataset"
   TotIALIT "Number of students with a literacy IA-assignment"
   TotIAMTH "Number of students with a math IA-assignment"
   TotIAATT "Number of students with an attendance IA-assignment"
   TotIABEH "Number of students with a behavior IA-assignment"
   TEAMIOGMinGrade "Lowest grade level specified for internal reporting purposes"
   TEAMIOGMaxGrade "Highest grade level specified for internal reporting purposes"
   SITEELAEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 ELA/Literacy Focus List"
   SITEMTHEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 Math Focus List"
   SITEATTEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 Attendance Focus List"
   SITEBEHEnrollGoal "ENROLL GOAL (EOY)\nSite-Level FY14 Behavior Focus List"
   SITEELAQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level ELA/Literacy Enrollment"
   SITEMTHQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level Math Enrollment"
   SITEATTQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level Attendance Enrollment"
   SITEBEHQ2EnrollBench "ENROLL GOAL (Q2)\nSite-Level Behavior Enrollment"
   SITEELAQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level ELA/Literacy Enrollment"
   SITEMTHQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level Math Enrollment"
   SITEATTQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level Attendance Enrollment"
   SITEBEHQ3EnrollBench "ENROLL GOAL (Q3)\nSite-Level Behavior Enrollment"
   SITEELADoseBench "DOSAGE GOAL (EOY)\nFY14 Site-Level ELA/Literacy Focus List Dosage (80% of FL enrollment will meet dosage target)"
   SITEMTHDoseBench "DOSAGE GOAL (EOY)\nFY14 Site-Level Math Focus List Dosage (80% of FL enrollment will meet dosage target)"
   SITEATTDoseBench "DOSAGE GOAL (EOY)\nFY14 Site-Level Attendance Focus List Dosage (80% of FL enrollment will meet dosage target)"
   SITEBEHDoseBench "DOSAGE GOAL (EOY)\nFY14 Site-Level Behavior Focus List Dosage (80% of FL enrollment will meet dosage target)"
   TEAMELAQ2DoseGoalMin "DOSAGE GOAL (Q2)\nMinimum Team-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ3DoseGoalMin "DOSAGE GOAL (Q3)\nMinimum Team-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ4DoseGoalMin "DOSAGE GOAL (Q4)\nMinimum Team-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ2DoseGoalMax "DOSAGE GOAL (Q2)\nMaximum Team-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ3DoseGoalMax "DOSAGE GOAL (Q3)\nMaximum Team-Level ELA/Literacy Per-Student (in hours)"
   TEAMELAQ4DoseGoalMax "DOSAGE GOAL (Q4)\nMaximum Team-Level ELA/Literacy Per-Student (in hours)"
   TEAMMTHQ2DoseGoalMin "DOSAGE GOAL (Q2)\nMinimum Team-Level Math Per-Student (in hours)"
   TEAMMTHQ3DoseGoalMin "DOSAGE GOAL (Q3)\nMinimum Team-Level Math Per-Student (in hours)"
   TEAMMTHQ4DoseGoalMin "DOSAGE GOAL (Q4)\nMinimum Team-Level Math Per-Student (in hours)"
   TEAMMTHQ2DoseGoalMax "DOSAGE GOAL (Q2)\nMaximum Team-Level Math Per-Student (in hours)"
   TEAMMTHQ3DoseGoalMax "DOSAGE GOAL (Q3)\nMaximum Team-Level Math Per-Student (in hours)"
   TEAMMTHQ4DoseGoalMax "DOSAGE GOAL (Q4)\nMaximum Team-Level Math Per-Student (in hours)"
   LITMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (ELA/Literacy, with overlap)"
   MTHMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Math, with overlap)"
   ATTMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Attendance, with overlap)"
   BEHMet30Enroll "ENROLL ACTUAL\nNumber of Students Enrolled 30+ Days (Behavior, with overlap)"
   LITMetQ2Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q2 Dosage Benchmark (with overlap)"
   LITMetQ3Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q3 Dosage Benchmark (with overlap)"
   LITMetQ4Dose "DOSAGE ACTUAL\nNumber of Students Meeting ELA/Literacy Q4 Dosage Benchmark (with overlap)"
   MTHMetQ2Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q2 Dosage Benchmark (with overlap)"
   MTHMetQ3Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q3 Dosage Benchmark (with overlap)"
   MTHMetQ4Dose "DOSAGE ACTUAL\nNumber of Students Meeting Math Q4 Dosage Benchmark (with overlap)"
   ATTMet56Dose "DOSAGE ACTUAL\nNumber of Students Enrolled 56+ Days (Attendance, with overlap)"
   BEHMet56Dose "DOSAGE ACTUAL\nNumber of Students Enrolled 56+ Days (Behavior, with overlap)"
   IOG_LIT35_OfficialFL "IOG: 3rd-5th Grade Literacy: Number of students on official focus lists"
   IOG_LIT69_OfficialFL "IOG: 6th-9th Grade Literacy: Number of students on official focus lists"
   IOG_MTH35_OfficialFL "IOG: 3rd-5th Grade Math: Number of students on official focus lists"
   IOG_MTH69_OfficialFL "IOG: 6th-9th Grade Math: Number of students on official focus lists"
   IOG_ATT35_OfficialFL "IOG: 3rd-5th Grade Attendance: Number of students on official focus lists"
   IOG_ATT69_OfficialFL "IOG: 6th-9th Grade Attendance: Number of students on official focus lists"
   IOG_BEH35_OfficialFL "IOG: 3rd-5th Grade Behavior: Number of students on official focus lists"
   IOG_BEH69_OfficialFL "IOG: 6th-9th Grade Bheavior: Number of students on official focus lists"
   LITAssess_anyRawDP "Number of students with at least one raw literacy assessment performance data point"
   LITAssess_2PerfLvlDP "Number of students with at least two literacy assessment performance level data points"
   LITAssess_StartOffSlid "Number of students who started off-track or sliding in literacy assessments"
   LITAssess_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in literacy assessments"
   IOG_LITAssess35_anyRawDP "IOG: 3rd-5th Grade Literacy Assessments: Number of students who had at least one raw performance data point"
   IOG_LITAssess35_2PerfLvlDP "IOG: 3rd-5th Grade Literacy Assessments: Number of students who had at least two performance level data points"
   IOG_LITAssess35_StartOffSlid "IOG: 3rd-5th Grade Literacy Assessments: Number of students who started off-track or sliding"
   IOG_LITAssess35_SOSMoveOn "IOG: 3rd-5th Grade Literacy Assessments: Number of students who started off-track or sliding and moved back on-track"
   IOG_LITAssess69_anyRawDP "IOG: 6th-9th Grade Literacy Assessments: Number of students who had at least one raw performance data point"
   IOG_LITAssess69_2PerfLvlDP "IOG: 6th-9th Grade Literacy Assessments: Number of students who had at least two performance level data points"
   IOG_LITAssess69_StartOffSlid "IOG: 6th-9th Grade Literacy Assessments: Number of students who started off-track or sliding"
   IOG_LITAssess69_SOSMoveOn "IOG: 6th-9th Grade Literacy Assessments: Number of students who started off-track or sliding and moved back on-track"
   BOCY_LITAssess35_StartOffSlid "Best of City Year: 3rd-5th Grade Literacy Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   BOCY_LITAssess69_StartOffSlid "Best of City Year: 6th-9th Grade Literacy Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   ELACG_anyRawDP "Number of students with at least one ELA course grade performance data point"
   ELACG_2PerfLvlDP "Number of students with at least two ELA course grade performance level data points"
   ELACG_StartOffSlid "Number of students who started off-track or sliding in ELA course grades"
   ELACG_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in ELA course grades"
   IOG_ELACG69_anyRawDP "IOG: 6th-9th Grade ELA Course Grades: Number of students who had at least one course grade performance data point"
   IOG_ELACG69_2PerfLvlDP "IOG: 6th-9th Grade ELA Course Grades: Number of students who had at least two performance level data points"
   IOG_ELACG69_StartOffSlid "IOG: 6th-9th Grade ELA Course Grades: Number of students who started off-track or sliding"
   IOG_ELACG69_SOSMoveOn "IOG: 6th-9th Grade ELA Course Grades: Number of students who started off-track or sliding and moved back on-track"
   MTHAssess_anyRawDP "Number of students with at least one raw math assessment performance data point"
   MTHAssess_2PerfLvlDP "Number of students with at least two math assessment performance level data points"
   MTHAssess_StartOffSlid "Number of students who started off-track or sliding in math assessments"
   MTHAssess_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in math assessments"
   IOG_MTHAssess35_anyRawDP "IOG: 3rd-5th Grade Math Assessments: Number of students who had at least one raw performance data point"
   IOG_MTHAssess35_2PerfLvlDP "IOG: 3rd-5th Grade Math Assessments: Number of students who had at least two performance level data points"
   IOG_MTHAssess35_StartOffSlid "IOG: 3rd-5th Grade Math Assessments: Number of students who started off-track or sliding"
   IOG_MTHAssess35_SOSMoveOn "IOG: 3rd-5th Grade Math Assessments: Number of students who started off-track or sliding and moved back on-track"
   IOG_MTHAssess69_anyRawDP "IOG: 6th-9th Grade Math Assessments: Number of students who had at least one raw performance data point"
   IOG_MTHAssess69_2PerfLvlDP "IOG: 6th-9th Grade Math Assessments: Number of students who had at least two performance level data points"
   IOG_MTHAssess69_StartOffSlid "IOG: 6th-9th Grade Math Assessments: Number of students who started off-track or sliding"
   IOG_MTHAssess69_SOSMoveOn "IOG: 6th-9th Grade Math Assessments: Number of students who started off-track or sliding and moved back on-track"
   BOCY_MTHAssess35_StartOffSlid "Best of City Year: 3rd-5th Grade Math Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   BOCY_MTHAssess69_StartOffSlid "Best of City Year: 6th-9th Grade Math Assessments: Number of students on official focus lists, who met dosage target, and started off-track or sliding"
   MTHCG_anyRawDP "Number of students with at least one math course grade performance data point"
   MTHCG_2PerfLvlDP "Number of students with at least two math course grade performance level data points"
   MTHCG_StartOffSlid "Number of students who started off-track or sliding in math course grades"
   MTHCG_SOSMoveOn "Number of students who started off-track or sliding and moved back on-track in math course grades"
   IOG_MTHCG69_anyRawDP "IOG: 6th-9th Grade Math Course Grades: Number of students who had at least one course grade performance data point"
   IOG_MTHCG69_2PerfLvlDP "IOG: 6th-9th Grade Math Course Grades: Number of students who had at least two performance level data points"
   IOG_MTHCG69_StartOffSlid "IOG: 6th-9th Grade Math Course Grades: Number of students who started off-track or sliding"
   IOG_MTHCG69_SOSMoveOn "IOG: 6th-9th Grade Math Course Grades: Number of students who started off-track or sliding and moved back on-track"
   ATT_anyRawDP "Number of students with at least one attendance (ADA) performance data point"
   ATT_2PerfLvlDP "Number of students with at least two attendance (ADA) performance level data points"
   ATT_StartLT90ADA "Number of students who started with less than 90% average daily attendance"
   ATT_SOSMoveOn "Number of students who started below 90% ADA and moved to at or above 90% ADA"
   IOG_ATT69_anyRawDP "IOG: 6th-9th Grade Attendance: Number of students who had at least one ADA performance data point"
   IOG_ATT69_2PerfLvlDP "IOG: 6th-9th Grade Attendance: Number of students who had at least two performance level data points"
   IOG_ATT69_StartLT90ADA "IOG: 6th-9th Grade Attendance: Number of students who started with less than 90% average daily attendance"
   IOG_ATT69_SOSMoveOn "IOG: 6th-9th Grade Attendance: Number of students who started below 90% ADA and moved to at or above 90% ADA"
   BOCY_ATT69_StartLT90ADA "Best of City Year: 6th-9th Grade Attendance: Number of students on official focus lists, enrolled 56+ days, and started with less than 90% average daily attendance"
   LITMetQ4DosePerc "DOSAGE ACTUAL\n% of Students Meeting ELA/Literacy Q4 Dosage Benchmark (out of ACTUAL FL Enrollment)"
   MTHMetQ4DosePerc "DOSAGE ACTUAL\n% of Students Meeting Math Q4 Dosage Benchmark (out of ACTUAL FL Enrollment)"
   ATTMet56DosePerc "DOSAGE ACTUAL\n% of Students Enrolled 56+ Days (Attendance, out of ACTUAL FL Enrollment)"
   BEHMet56DosePerc "DOSAGE ACTUAL\n% of Students Enrolled 56+ Days (Behavior, out of ACTUAL FL Enrollment)"
   IOG_LITAssess35_SOSMoveOnPerc "IOG ACTUAL\n3rd-5th Grade Literacy: % of Students who Moved from Below Benchmark on Literacy Skills Assessments to At/Above Benchmark"
   IOG_LITAssess69_SOSMoveOnPerc "IOG ACTUAL\n6th-9th Grade Literacy: % of Students who Moved from Below Benchmark on Literacy Skills Assessments to At/Above Benhcmark"
   IOG_ELACG69_SOSMoveOnPerc 'IOG ACTUAL\n6th-9th Grade ELA: % of Students who Moved from an ELA Course Grade of "D" or Lower to a "C" or Higher'
   IOG_MTHAssess35_SOSMoveOnPerc "IOG ACTUAL\n3rd-5th Grade Math: % of Students who Moved from Below Benchmark on Math Skills Assessments to At/Above Benchmark"
   IOG_MTHAssess69_SOSMoveOnPerc "IOG ACTUAL\n6th-9th Grade Math: % of Students who Moved from Below Benchmark on Math Skills Assessments to At/Above Benchmark"
   IOG_MTHCG69_SOSMoveOnPerc 'IOG ACTUAL\n6th-9th Grade Math: % of Students who Moved from a Math Course Grade of "D" or Lower to a "C" or Higher'
   IOG_ATT69_SOSMoveOnPerc "IOG ACTUAL\n6th-9th Grade Attendance: % of Students who Moved from Below 90% ADA to At/Above 90% ADA".

VALUE LABELS RegionID 1 "Atlantic"
2 "Midwest"
3 "Northeast"
4 "South"
5 "West".
EXECUTE.

***** No longer need TEAMAGG dataset.
DATASET CLOSE TEAMAGG.

************************************************************************************************************************************************************************************
*****END OF SYNTAX FILE.
************************************************************************************************************************************************************************************