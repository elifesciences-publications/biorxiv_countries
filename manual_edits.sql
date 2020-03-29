--- A null affiliation string should be classified as "unknown"
UPDATE prod.article_authors SET affiliation='!!unknown!!' WHERE affiliation IS NULL;
INSERT INTO prod.affiliation_institutions (affiliation, institution) VALUES ('!!unknown!!',0)

--- Get rid of articles that ran into crawler errors
DELETE FROM prod.article_authors
WHERE article IN (
	SELECT DISTINCT article
	FROM prod.article_authors
	WHERE name='000bad_data000'
)

--- Get rid of traffic data after 2019
DELETE FROM prod.article_traffic WHERE year=2020

--- MRC institutions misattributed to Buddhist center
UPDATE prod.affiliation_institutions SET institution=4656 WHERE institution=4254;

--- MIT
UPDATE prod.affiliation_institutions SET institution=175 WHERE institution=856;

--- Broad Institute (do AFTER MIT)
UPDATE prod.affiliation_institutions SET institution=1796 WHERE affiliation LIKE '%Broad%MIT%';

--- Add entry for university of california (ALREADY DONE):
--- INSERT INTO prod.institutions (name, ror, grid, country) VALUES ('University of California System','https://ror.org/00pjdza24','grid.30389.31','US')

--- Fix entries assigned to california coast university
UPDATE prod.affiliation_institutions SET institution=10923 WHERE institution=62;

--- Let's say the Chan Zuckerberg Biohub is the same as CZI for now
UPDATE prod.affiliation_institutions SET institution=2571 WHERE institution=0 AND affiliation LIKE '%Chan%Zuckerberg%';

--- Jackson Lab
UPDATE prod.affiliation_institutions SET institution=2134 WHERE institution=0 AND affiliation LIKE '%Jackson Lab%';

--- Institute for Systems Biology is all over the place, but assigning them to the Seattle one is less wrong than assigning them all to a Russian company
UPDATE prod.affiliation_institutions SET institution=5107 WHERE institution=4768;

--- No entry for this, but lots of authors:
--- INSERT INTO prod.institutions (name, ror, grid, country) VALUES ('China National Gene Bank','NONE','','CN')
UPDATE prod.affiliation_institutions SET institution=10924 WHERE affiliation LIKE '%China National Gene%';

--- There's some French place called "Public Health" that gets misattributed dozens of associations
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=63;
-- Ditto "Computer Science Department"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=1314;
--- And "Department of Biological Sciences"?!
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=720;
--- "Biotechnology Institute"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=256;
--- "Ministry of Health"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=1111;
--- "Department of Virology"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=757;
--- "Laboratory of BioChemistry"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=5162;
--- "Applied Mathematics (United States)"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=726;

--- Harvard's school of public health is a blind spot
UPDATE prod.affiliation_institutions SET institution=810 WHERE affiliation LIKE '%Chan School%';

--- School within Radboud University
UPDATE prod.affiliation_institutions SET institution=1097 WHERE affiliation LIKE '%Donders Institute%';

--- Austrian research institute not recognized
UPDATE prod.affiliation_institutions SET institution=2057 WHERE affiliation LIKE '%CeMM%';

--- Anything with "Washington" in it isn't reliable, but all are in USA
UPDATE prod.affiliation_institutions SET institution=2090 WHERE institution=0 AND affiliation LIKE '%George Washington University%';
UPDATE prod.affiliation_institutions SET institution=2096 WHERE institution=0 AND affiliation LIKE '%Washington University%';
--- Fixing University of Washington entries
UPDATE prod.affiliation_institutions SET institution=4854 WHERE institution=104 AND affiliation LIKE '%Washington University%';
UPDATE prod.affiliation_institutions SET institution=2096 WHERE institution=152 AND affiliation LIKE '%Washington University%';

--- Blind spot for Carnegie Mellon
UPDATE prod.affiliation_institutions SET institution=1968 WHERE institution=0 AND affiliation LIKE '%Carnegie Mellon%';

--- UNC assignments all messed up, but not UNC Charlotte
UPDATE prod.affiliation_institutions SET institution=1283 WHERE institution<>40 AND affiliation LIKE '%University of North Carolina%';

--- Chinese institute unrecognized
UPDATE prod.affiliation_institutions SET institution=549 WHERE affiliation LIKE '%Watson Institute of Genome Sciences%';

--- "Illumnia" is recognized but not Illumina Inc
UPDATE prod.affiliation_institutions SET institution=4787 WHERE institution=0 AND affiliation LIKE '%Illumina%';

--- Center for the Unknown
UPDATE prod.affiliation_institutions SET institution=2558 WHERE institution=0 AND affiliation LIKE '%Champalimaud%';

--- Unusual misses for Weill Cornell Medicine
UPDATE prod.affiliation_institutions SET institution=4467 WHERE institution=0 AND affiliation LIKE '%Weill Cornell%Qatar%';
UPDATE prod.affiliation_institutions SET institution=662 WHERE institution=0 AND affiliation LIKE '%Weill Cornell%';

--- Misses for Erasmus Medical Center
UPDATE prod.affiliation_institutions SET institution=1644 WHERE institution=0 AND affiliation LIKE '%Erasmus M%';

--- Misses for Johns Hopkins
UPDATE prod.affiliation_institutions SET institution=3604 WHERE institution=0 AND affiliation LIKE '%Johns Hopkins S%';
UPDATE prod.affiliation_institutions SET institution=219 WHERE institution=0 AND affiliation LIKE '%Johns Hopkins%';

--- Misassignment for biotech company
UPDATE prod.affiliation_institutions SET institution=0 WHERE affiliation LIKE '%Calico%';

--- Dartmouth
UPDATE prod.affiliation_institutions SET institution=2592 WHERE institution=0 AND affiliation LIKE '%Geisel School%';

--- Assign all the unassigned UMD entries to UMCP
UPDATE prod.affiliation_institutions SET institution=2074 WHERE institution=0 AND affiliation LIKE '%University of Maryland%';

--- Harvard
UPDATE prod.affiliation_institutions SET institution=14 WHERE institution=0 AND affiliation LIKE '%Harvard Me%';
UPDATE prod.affiliation_institutions SET institution=810 WHERE institution=0 AND affiliation LIKE '%Harvard%';
UPDATE prod.affiliation_institutions SET institution=810 WHERE institution=0 AND affiliation LIKE '%Wyss I%';

--- Lots of misses for Ben-Gurion University
UPDATE prod.affiliation_institutions SET institution=1515 WHERE institution=0 AND affiliation LIKE '%Ben-Gurion%';

--- Miss for Duke Hospital
UPDATE prod.affiliation_institutions SET institution=3627 WHERE institution=0 AND affiliation LIKE '%Duke University Med%';


--- REMOVE ANY PAPERS WITH A MOST RECENT VERSION IN 2020
DELETE FROM prod.article_authors WHERE observed >= '2020-01-01';

--- Novartis Institutes for Biomedical Research consistently misassigned, and most references are ambiguous about country location
UPDATE prod.affiliation_institutions SET institution=0 WHERE affiliation LIKE '%Novartis Institute%';

--- VIB is a Belgian research institute, not the Volgograd Institute of Business
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=1295 AND affiliation LIKE '%VIB%';

--- Institute of Microbiology
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=1527;
--- Institute of Biology
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=3363;
--- Department of Plant Biology
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=1967;
--- Every other weird "Department of"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution IN (
    SELECT id FROM prod.institutions
    WHERE name LIKE 'Department of%'
);
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution IN (
    SELECT id FROM prod.institutions
    WHERE name LIKE 'Institute of%'
);
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution IN (
    SELECT id FROM prod.institutions
    WHERE name LIKE 'Center for%'
);
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution IN (
    SELECT id FROM prod.institutions
    WHERE name LIKE 'Ministry of%'
);

--- "Animal Medical Center"
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=3577;

--- Lots of affiliations for Jinzhou Medical University, but no entry in GRID for it
UPDATE prod.affiliation_institutions SET institution=9906 WHERE institution=0 AND affiliation LIKE '%Jinzhou%';

---Public/private partnership at UW-Madison
UPDATE prod.affiliation_institutions SET institution=499 WHERE institution=0 AND affiliation LIKE '%Morgridge Institute%';

---Public/private partnership at UW-Madison
UPDATE prod.affiliation_institutions SET institution=5155 WHERE institution=0 AND affiliation LIKE '%Sun Yat%';
--- Taiwan has another with similar name
UPDATE prod.affiliation_institutions SET institution=6835 WHERE affiliation LIKE '%National Sun Yat%';

--- Lots of misses for University of Bergen
UPDATE prod.affiliation_institutions SET institution=1801 WHERE institution=0 AND affiliation LIKE '%University of Bergen%';

--- Nothing but miscalls for Magnetic Resonance Imaging Institute for Biomedical Research
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=932;

--- References to "Microsoft Research" are ambiguous at the country level
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=4832; --- germany

--- Chinese Academy of Sciences
UPDATE prod.affiliation_institutions SET institution=1160 WHERE institution=0 AND affiliation LIKE '%University%Chinese Academy of Sciences%';
UPDATE prod.affiliation_institutions SET institution=606 WHERE institution=0 AND affiliation LIKE '%Chinese Academy of Sciences%';

--- Miscall for Beijing Genomics Institute as Mahatma Ghandi Institute
UPDATE prod.affiliation_institutions SET institution=1161 WHERE institution=4916;

--- Center housed at Cornell
UPDATE prod.affiliation_institutions SET institution=881 WHERE affiliation LIKE '%Boyce Thompson%';

--- Inconsistent assignment for Yale School of Public Health
UPDATE prod.affiliation_institutions SET institution=727 WHERE institution=0 AND affiliation LIKE '%Yale%Public Health%';

--- Inconsistent assignment for Wageningen University
UPDATE prod.affiliation_institutions SET institution=610 WHERE institution=0 AND affiliation LIKE '%Wageningen%';

--- FAU
UPDATE prod.affiliation_institutions SET institution=3545 WHERE institution=0 AND affiliation LIKE '%Florida Atlantic%';

--- Abbreviated references to UC Santa Cruz
UPDATE prod.affiliation_institutions SET institution=1636 WHERE institution=0 AND affiliation LIKE '%UC Santa%';

--- Missing matches to University of Calgary
UPDATE prod.affiliation_institutions SET institution=809 WHERE institution=0 AND affiliation LIKE '%University of Calgary%';

--- Miscall for Northeastern
UPDATE prod.affiliation_institutions SET institution=2106 WHERE institution=1010 AND affiliation LIKE '%Northeastern U%';

--- Missing matches to University of Colorado
UPDATE prod.affiliation_institutions SET institution=1000 WHERE institution=0 AND affiliation LIKE '%University of Colorado%';

--- Some mentions of Penn State University Park misassigned to "Park University"
UPDATE prod.affiliation_institutions SET institution=474 WHERE institution=33;

--- Florida Neuroscience Center got some assignments that should be University of California
UPDATE prod.affiliation_institutions SET institution=10923 WHERE institution=3628 AND affiliation LIKE '%University of Calif%';

--- Incorrect mapping to People's Bank of China
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=4900;

--- "LMU" is Ludwig Maximilian University, not Loyola Merrimount University
UPDATE prod.affiliation_institutions SET institution=209 WHERE institution=3637;

--- Lots of misassignments to some entity called "Brain"
UPDATE prod.affiliation_institutions SET institution=558 WHERE institution=502 AND affiliation LIKE '%Western Ontario%';
UPDATE prod.affiliation_institutions SET institution=558 WHERE institution=502 AND affiliation LIKE '%Western University%';

UPDATE prod.affiliation_institutions SET institution=908 WHERE institution=502 AND affiliation LIKE '%University of Sydney%';

UPDATE prod.affiliation_institutions SET institution=662 WHERE institution=502 AND affiliation LIKE '%Cornell%';

UPDATE prod.affiliation_institutions SET institution=328 WHERE institution=502 AND affiliation LIKE '%Humboldt%';

UPDATE prod.affiliation_institutions SET institution=86 WHERE institution=502 AND affiliation LIKE '%Aalto%';

UPDATE prod.affiliation_institutions SET institution=1329 WHERE institution=502 AND affiliation LIKE '%Brain and Vision Research Laboratory%';

UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=502;

--- No way to know which GlaxoSmithKline is being referred to
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=3623 OR institution=3624 OR institution=6776;

--- All the matches to China Institute of Communications are poorly specified departments in France?
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=3601;

--- UPF-CSIC is not University of Passo Fundo, nor is it a descriptive acronym
UPDATE prod.affiliation_institutions SET institution=1006 WHERE institution=1654 AND affiliation LIKE '%CSIC%';

--- Miscall for center at Heidelberg University
UPDATE prod.affiliation_institutions SET institution=1213 WHERE institution=632 AND affiliation LIKE '%COS%';

--------------------------
-------Clearing up unknown institutions
UPDATE prod.affiliation_institutions SET institution=1537 WHERE institution=0 AND affiliation LIKE '%Purdue U%';

UPDATE prod.affiliation_institutions SET institution=3719 WHERE institution=0 AND affiliation LIKE '%Mayo Clinic%';

UPDATE prod.affiliation_institutions SET institution=74 WHERE institution=0 AND affiliation LIKE '%Uppsala U%';

UPDATE prod.affiliation_institutions SET institution=1097 WHERE institution=0 AND affiliation LIKE '%Radboud U%';

UPDATE prod.affiliation_institutions SET institution=2084 WHERE institution=0 AND affiliation LIKE '%University of Texas%';

UPDATE prod.affiliation_institutions SET institution=10923 WHERE institution=0 AND affiliation LIKE '%University of California%';

---INSERT INTO prod.institutions (name, ror, grid, country) VALUES ('Novartis (United States)','https://ror.org/028fhxy95','grid.418424.f','US')

UPDATE prod.affiliation_institutions SET institution=11521 WHERE institution=0 AND affiliation LIKE '%Novartis Institutes%';

---INSERT INTO prod.institutions (name, ror, grid, country) VALUES ('Africa City of Technology','NONE','NONE','SD')

UPDATE prod.affiliation_institutions SET institution=11522 WHERE institution=0 AND affiliation LIKE '%Africa City of Technology%';

UPDATE prod.affiliation_institutions SET institution=5979 WHERE institution=0 AND affiliation LIKE '%Regeneron%';

UPDATE prod.affiliation_institutions SET institution=121 WHERE institution=0 AND affiliation LIKE '%Bio21%';

UPDATE prod.affiliation_institutions SET institution=72 WHERE institution=0 AND affiliation LIKE '%Tata Institute%';

UPDATE prod.affiliation_institutions SET institution=139 WHERE institution=0 AND affiliation LIKE '%University of Birmingham%';

UPDATE prod.affiliation_institutions SET institution=99 WHERE institution=0 AND affiliation LIKE '%University of Helsinki%';

UPDATE prod.affiliation_institutions SET institution=4774 WHERE institution=0 AND affiliation LIKE '%Institute of Science and Technology Austria%';

UPDATE prod.affiliation_institutions SET institution=552 WHERE institution=0 AND affiliation LIKE '%Leiden%';

UPDATE prod.affiliation_institutions SET institution=119 WHERE institution=0 AND affiliation LIKE '%Academia Sinica%';

UPDATE prod.affiliation_institutions SET institution=1965 WHERE institution=0 AND affiliation LIKE '%Carnegie Institution%';

UPDATE prod.affiliation_institutions SET institution=1074 WHERE institution=0 AND affiliation LIKE '%Michigan State%';

UPDATE prod.affiliation_institutions SET institution=528 WHERE institution=0 AND affiliation LIKE '%Amgen%';

UPDATE prod.affiliation_institutions SET institution=35 WHERE institution=0 AND affiliation LIKE '%University of Georgia%';

UPDATE prod.affiliation_institutions SET institution=1229 WHERE institution=0 AND affiliation LIKE '%Indiana University%';

UPDATE prod.affiliation_institutions SET institution=17 WHERE institution=0 AND affiliation LIKE '%Indian Institute of Science%';

UPDATE prod.affiliation_institutions SET institution=17 WHERE institution=0 AND affiliation LIKE '%Indian Institute of Science%';

UPDATE prod.affiliation_institutions SET institution=5015 WHERE institution=0 AND affiliation LIKE '%Univ%Rennes%';

UPDATE prod.affiliation_institutions SET institution=89 WHERE institution=0 AND affiliation LIKE '%Lundbeck Foundation%';

UPDATE prod.affiliation_institutions SET institution=2595 WHERE institution=0 AND affiliation LIKE '%Marquette%';

UPDATE prod.affiliation_institutions SET institution=1296 WHERE institution=0 AND affiliation LIKE '%Van Andel%';

UPDATE prod.affiliation_institutions SET institution=2032 WHERE institution=0 AND affiliation LIKE '%University of Arkansas%';

UPDATE prod.affiliation_institutions SET institution=5840 WHERE institution=0 AND affiliation LIKE '%Max Planck Institute for Marine Microbiology%';

UPDATE prod.affiliation_institutions SET institution=264 WHERE institution=0 AND affiliation LIKE '%Indian Institute of Technology%';

UPDATE prod.affiliation_institutions SET institution=2592 WHERE institution=0 AND affiliation LIKE '%Dartmouth%';

UPDATE prod.affiliation_institutions SET institution=2130 WHERE institution=0 AND affiliation LIKE '%Greifswald%';

UPDATE prod.affiliation_institutions SET institution=1199 WHERE institution=0 AND affiliation LIKE '%Wellcome%';

UPDATE prod.affiliation_institutions SET institution=2157 WHERE institution=0 AND affiliation LIKE '%at Buffalo%';

UPDATE prod.affiliation_institutions SET institution=3407 WHERE institution=0 AND affiliation LIKE '%Tartu%';

UPDATE prod.affiliation_institutions SET institution=2590 WHERE institution=0 AND affiliation LIKE '%Max Planck Society%';

UPDATE prod.affiliation_institutions SET institution=764 WHERE institution=0 AND affiliation LIKE '%Australian Research%';

UPDATE prod.affiliation_institutions SET institution=1308 WHERE institution=0 AND (affiliation LIKE '%Leipzig U%' OR affiliation LIKE '%University of Leipzig%');

UPDATE prod.affiliation_institutions SET institution=499 WHERE institution=0 AND affiliation LIKE '%Wisconsin National Primate%';

UPDATE prod.affiliation_institutions SET institution=1289 WHERE institution=0 AND affiliation LIKE '%South Dakota Center%';

---Change the 'Institut National de la Recherche Agronomique' to point to the French institution and not the entry in Morocco
UPDATE prod.institutions SET ror='https://ror.org/01x3gbx83', grid='grid.414548.8', country='FR' WHERE id=383;

---Cancer center in Canada attributed to Tuvalu
UPDATE prod.affiliation_institutions SET institution=5000 WHERE institution=4587;

--- *** REMOVE all institutions that now have no affiliations linked to them:
random line of nonsense characters here to prevent this query from running accidentally asdflkjaspodfijapsdijf

DELETE FROM prod.institutions
WHERE id IN (
	SELECT id
	FROM (
		SELECT i.id, COUNT(a.institution) AS total
		FROM prod.institutions i
		LEFT JOIN prod.affiliation_institutions a ON i.id=a.institution
		GROUP BY 1
		ORDER BY 2 ASC
	) AS totalaff
	WHERE total=0
)
---

-------
---ALL EDITS BELOW THIS LINE WERE MADE AFTER THE ACCURACY CALCULATIONS
-------

---Authors from French CNRS misattributed to Lebanese National Council for Scientific Research
UPDATE prod.affiliation_institutions SET institution=1234 WHERE institution=10896;
