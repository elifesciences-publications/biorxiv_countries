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

--- "Illumina" is recognized but not Illumina Inc
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

---Lots of misattributed affiliations to the Sudanese Academy of Engineering Sciences
UPDATE prod.affiliation_institutions SET institution=0 WHERE institution=3173;

---Confusion between Western Caspian University and Western University
UPDATE prod.affiliation_institutions SET institution=558 WHERE institution=1977 AND affiliation LIKE '%Western University%';

---The relevant "Institut de Recherche pour le Développement" is in France, not Bolivia
UPDATE prod.institutions SET ror='https://ror.org/05q3vnk25', grid='grid.4399.7', country='FR' WHERE id=3599;

--- PNAS is reported in bioRxiv as two different names
UPDATE publications SET journal='PNAS' WHERE journal='Proceedings of the National Academy of Sciences'



--- REVISION CORRECTIONS START HERE ---------------
--- Chan Zuckerburg
UPDATE prod.affiliation_institutions SET institution=2571 WHERE institution=0 AND affiliation LIKE '%Chan Zuckerburg%';

--- Institut für Populationsgenetik is at Vetmeduni Vienna
UPDATE prod.affiliation_institutions SET institution=1722 WHERE institution=0 AND affiliation LIKE '%Populationsgenetik%';

UPDATE prod.affiliation_institutions SET institution=1722 WHERE institution=0 AND affiliation LIKE '%Vetmeduni%';

--- All "Collaborative Innovation Center" affiliations are in China
UPDATE prod.affiliation_institutions SET institution=1028 WHERE institution=0 AND affiliation LIKE '%Collaborative Innovation Center%';

--- Africa City of Technology
UPDATE prod.affiliation_institutions SET institution=11522 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%africa city of technology%');

--- National Centre for Biological Science in Bangalore
UPDATE prod.affiliation_institutions SET institution=72 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%National Centre for Biological Sciences%');

--- Leibniz neurobiology
UPDATE prod.affiliation_institutions SET institution=3250 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Center for Behavioral Brain Sciences%');

--- Center in Chile
UPDATE prod.affiliation_institutions SET institution=6832 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%invasal%');

--- Center in Belgium
UPDATE prod.affiliation_institutions SET institution=250 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%VIB%');

--- Microsoft Research bylines almost all in USA
--- INSERT INTO prod.institutions (name, ror, grid, country) VALUES ('Microsoft (United States)','https://ror.org/00d0nc645','grid.419815.0','US')
UPDATE prod.affiliation_institutions SET institution=11576 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%microsoft%');

--- Center at Max Planck Institute
UPDATE prod.affiliation_institutions SET institution=2232 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Center for Systems Biology%dresden%');

--- Network of Leibniz research institutes all in Germany
UPDATE prod.affiliation_institutions SET institution=10979 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%leibniz%');

--- Center at Berlin Brandenburg Institute of Advanced Biodiversity Research
UPDATE prod.affiliation_institutions SET institution=1144 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Berlin % for Genomics%');

--- technical university of berlin
UPDATE prod.affiliation_institutions SET institution=1150 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Technische%berlin%');

--- German Cancer Consortium
UPDATE prod.affiliation_institutions SET institution=710 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%German Cancer%');

--- Barts/London School of Medicine
UPDATE prod.affiliation_institutions SET institution=202 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%London School of Medicine%');

--- South Korean startup
UPDATE prod.affiliation_institutions SET institution=3681 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Tomocube%');

---------- CITY/COUNTRY AFFILIATIONS START HERE

--- Strasbourg France
UPDATE prod.affiliation_institutions SET institution=2723 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Strasbourg%');

--- Quebec Canada
UPDATE prod.affiliation_institutions SET institution=2450 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Qu_bec%');

--- San Martin, Peru
--- INSERT INTO prod.institutions (name, ror, grid, country) VALUES ('Universidad Nacional de San Martin','https://ror.org/02h7fsz12','grid.441968.6','PE')
UPDATE prod.affiliation_institutions SET institution=11577 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%San Mart_n%') AND LOWER(affiliation) NOT LIKE LOWER('%San Martino%')

--- Bohemia (Czechia)
UPDATE prod.affiliation_institutions SET institution=4377 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%South Bohemia%');

--- Jiangsu China
UPDATE prod.affiliation_institutions SET institution=4857 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Jiangsu%');

--- Qingdao China
UPDATE prod.affiliation_institutions SET institution=2917 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Qingdao%');

--- All "Jerusalem" mentions are from same university
UPDATE prod.affiliation_institutions SET institution=57 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Hebrew University of Jerusalem%');

--- Potsdam Germany
UPDATE prod.affiliation_institutions SET institution=1317 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Potsdam%');

--- Vigo Spain
UPDATE prod.affiliation_institutions SET institution=39 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Universidad%Vigo%');

--- Abu Dhabi UAE
UPDATE prod.affiliation_institutions SET institution=5019 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Abu Dhabi%');

---  New York USA
UPDATE prod.affiliation_institutions SET institution=497 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%New York%');

---  Shanghai China
UPDATE prod.affiliation_institutions SET institution=1940 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Shanghai%');

---  Seattle USA
UPDATE prod.affiliation_institutions SET institution=4130 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Seattle%');

---  Gothenburg Sweden
UPDATE prod.affiliation_institutions SET institution=1546 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Gothenburg%');

---  University in Helsinki Finland
UPDATE prod.affiliation_institutions SET institution=99 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Folkh_lsan%');

---  Munich Germany
UPDATE prod.affiliation_institutions SET institution=209 WHERE (LOWER(affiliation) LIKE LOWER('%Munich%') OR LOWER(affiliation) LIKE LOWER('%M_nchen%')) AND institution=0

---  Alabama USA
UPDATE prod.affiliation_institutions SET institution=3437 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Alabama%');

---  Wisconsin USA
UPDATE prod.affiliation_institutions SET institution=499 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Wisconsin%');

---  Berlin Germany
UPDATE prod.affiliation_institutions SET institution=465 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Berlin%');

---  Zhejiang China
UPDATE prod.affiliation_institutions SET institution=549 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Zhejiang%');

---  Netherlands
UPDATE prod.affiliation_institutions SET institution=4566 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Netherlands%');

---  Austria
UPDATE prod.affiliation_institutions SET institution=167 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Austria%');

---  Frankfurt Germany
UPDATE prod.affiliation_institutions SET institution=711 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Frankfurt%');

---  Paris France
UPDATE prod.affiliation_institutions SET institution=16 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Paris%');

---  Iowa USA
UPDATE prod.affiliation_institutions SET institution=95 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('% Iowa%');

---  Freiburg Germany
UPDATE prod.affiliation_institutions SET institution=452 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Freiburg%');

--- Canada
UPDATE prod.affiliation_institutions SET institution=742 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Canada%');

--- Pennsylvania USA
UPDATE prod.affiliation_institutions SET institution=20 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Pennsylvania%');

--- Leuven Belgium
UPDATE prod.affiliation_institutions SET institution=250 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Leuven%');

--- Puerto Rico USA
UPDATE prod.affiliation_institutions SET institution=1580 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Puerto Rico%');

--- New Jersey USA
UPDATE prod.affiliation_institutions SET institution=1085 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%New Jersey%');

--- Uppsala Sweden
UPDATE prod.affiliation_institutions SET institution=74 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Uppsala%');

--- Mongolia
UPDATE prod.affiliation_institutions SET institution=3322 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Mongolia%') AND LOWER(affiliation) NOT LIKE LOWER('%Inner Mongolia%')

--- Inner Mongolia, China
UPDATE prod.affiliation_institutions SET institution=1102 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Mongolia%');

--- Virginia USA
UPDATE prod.affiliation_institutions SET institution=1208 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Virginia%');

--- India
UPDATE prod.affiliation_institutions SET institution=17 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%India%');

--- Shandong China
UPDATE prod.affiliation_institutions SET institution=2213 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Shandong%');

--- British Columbia, Canada
UPDATE prod.affiliation_institutions SET institution=1061 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%British Columbia%');

--- Beijing China
UPDATE prod.affiliation_institutions SET institution=1112 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Beijing%');

--- China
UPDATE prod.affiliation_institutions SET institution=1102 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%China%');

--- Nanjing China
UPDATE prod.affiliation_institutions SET institution=1386 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Nanjing%');

--- Amsterdam Netherlands
UPDATE prod.affiliation_institutions SET institution=127 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Amsterdam%');

--- Lots of affiliations in Shenzhen
UPDATE prod.affiliation_institutions SET institution=2089 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%shenzhen%');

--- Poitiers France
UPDATE prod.affiliation_institutions SET institution=5193 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Poitiers%');

--- Zurich Switzerland
UPDATE prod.affiliation_institutions SET institution=669 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Zurich%');

--- Trento Italy
UPDATE prod.affiliation_institutions SET institution=611 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Trento%');

--- Kumamoto Japan
UPDATE prod.affiliation_institutions SET institution=2066 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Kumamoto%');

--- Denmark
UPDATE prod.affiliation_institutions SET institution=966 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Denmark%');

--- Malaysia
UPDATE prod.affiliation_institutions SET institution=4 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Malaysia%');

--- Russia
UPDATE prod.affiliation_institutions SET institution=83 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Russia%');

--- Thailand
UPDATE prod.affiliation_institutions SET institution=3595 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Thailand%');

--- Poland
UPDATE prod.affiliation_institutions SET institution=3031 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Poland%');

--- South Korea
UPDATE prod.affiliation_institutions SET institution=3681 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Korea%');

--- New Zealand
UPDATE prod.affiliation_institutions SET institution=8401 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%New Zealand%');

--- Washington, USA (multiple)
UPDATE prod.affiliation_institutions SET institution=152 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Washington%');

--- Lisbon, Portugal
UPDATE prod.affiliation_institutions SET institution=963 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Lisboa%');

--- Boston, USA
UPDATE prod.affiliation_institutions SET institution=1329 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Boston%');

--- Italy
UPDATE prod.affiliation_institutions SET institution=553 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Italian%');

--- Negev Israel
UPDATE prod.affiliation_institutions SET institution=1515 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Negev%');

--- Tasmania Australia
UPDATE prod.affiliation_institutions SET institution=3446 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Tasmania%');

--- Massachusetts USA
UPDATE prod.affiliation_institutions SET institution=175 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Massachusetts%');

--- Norway
UPDATE prod.affiliation_institutions SET institution=2343 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Norwegian%');

--- Granada Spain
UPDATE prod.affiliation_institutions SET institution=574 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Granada%');

--- Qatari center
UPDATE prod.affiliation_institutions SET institution=4397 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Sidra%');

--- Texas, USA
UPDATE prod.affiliation_institutions SET institution=2084 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Texas%');

------ Word frequency based edits begin here
--- Almost all Cambridge strings are in the UK
UPDATE prod.affiliation_institutions SET institution=31 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Cambridge%');

--- Genentech is in California USA
UPDATE prod.affiliation_institutions SET institution=974 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%genentech%');

--- Chinese in China
UPDATE prod.affiliation_institutions SET institution=352 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%chinese%');

--- CSIR in India
UPDATE prod.affiliation_institutions SET institution=17 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%csir%');

--- London in UK
UPDATE prod.affiliation_institutions SET institution=88 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%london%');

--- Stanford in USA
UPDATE prod.affiliation_institutions SET institution=453 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Stanford%');

--- "UK " in UK
UPDATE prod.affiliation_institutions SET institution=88 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%uk %');

--- Hebrew University in Israel
UPDATE prod.affiliation_institutions SET institution=57 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%hebrew univ%');

--- Goethe University in Germany
UPDATE prod.affiliation_institutions SET institution=711 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Goethe%');

--- CNRS in France
UPDATE prod.affiliation_institutions SET institution=2856 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%cnrs%');

--- CSIC in Spain
UPDATE prod.affiliation_institutions SET institution=1611 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%csic%');

--- San Francisco in USA
UPDATE prod.affiliation_institutions SET institution=974 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%san francisco%');

--- California in USA
UPDATE prod.affiliation_institutions SET institution=974 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%California%');

--- Wake Forest in USA
UPDATE prod.affiliation_institutions SET institution=2184 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Wake Forest%');

--- Guangdong in China
UPDATE prod.affiliation_institutions SET institution=4430 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Guangdong%');

--- Icahn School in USA
UPDATE prod.affiliation_institutions SET institution=212 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%icahn%');

--- Barcelona in Spain
UPDATE prod.affiliation_institutions SET institution=672 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Barcelona%');

--- Switzerland
UPDATE prod.affiliation_institutions SET institution=1226 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%swiss%');

--- Penn State in USA
UPDATE prod.affiliation_institutions SET institution=474 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Penn%');

--- Imperial College in UK
UPDATE prod.affiliation_institutions SET institution=302 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%Imperial%');

--- Palo Alto in USA
UPDATE prod.affiliation_institutions SET institution=8279 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%palo alto%');

--- Fox Chase Cancer Center in USA
UPDATE prod.affiliation_institutions SET institution=2069 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%fox chase%');
