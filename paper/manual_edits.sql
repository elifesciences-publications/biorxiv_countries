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

--- Monash U in Australia
UPDATE prod.affiliation_institutions SET institution=559 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%monash%');

--- Heinrich Heine U in Germany
UPDATE prod.affiliation_institutions SET institution=1551 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%heine%');

--- Calico (company) in California
UPDATE prod.affiliation_institutions SET institution=974 WHERE institution=0 AND LOWER(affiliation) LIKE LOWER('%calico%');


----- DOING EMAIL CORRECTIONS STARTS HERE
--- first, we add a field with the originally scraped affiliations
--ALTER TABLE article_authors ADD COLUMN original_affiliation text;
--UPDATE article_authors SET original_affiliation = affiliation;


UPDATE article_authors
SET affiliation='EMAIL INFERENCE: United Arab Emirates'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.ae'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Argentina'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.ar'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Austria'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.at'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Australia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.au'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Bangladesh'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.bd'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Belgium'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.be'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Bulgaria'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.bg'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Brazil'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.br'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Canada'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ca'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Catalonia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.cat'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Switzerland'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ch'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Chile'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.cl'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: China'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%.cn'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Colombia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.co'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Cyprus'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.cy'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Czechia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.cz'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Germany'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.de'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Denmark'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.dk'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: United States'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.edu'


UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Estonia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ee'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Spain'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.es'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Finland'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.fi'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: France'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.fr'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Ghana'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.gh'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: United States'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.gov'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Greece'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.gr'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Hong Kong'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.hk'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Croatia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.hr'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Hungary'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.hu'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Indonesia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.id'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Ireland'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ie'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Israel'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.il'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: India'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.in'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Iran'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ir'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Italy'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.it'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Japan'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.jp'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: South Korea'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.kr'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Luxembourg'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.lu'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Macau'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.mo'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Mexico'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.mx'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Malaysia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.my'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Netherlands'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.nl'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Norway'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.no'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: New Zealand'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.nz'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Poland'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.pl'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Portugal'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.pt'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Qatar'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.qa'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Romania'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ro'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Russia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ru'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Saudi Arabia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.sa'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Sweden'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.se'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Singapore'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.sg'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Slovenia'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.si'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Turkey'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.tr'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Taiwan'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.tw'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: Ukraine'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.ua'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: United Kingdom'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.uk'
)

UPDATE article_authors
SET affiliation='EMAIL INFERENCE: South Africa'
WHERE id IN (
	SELECT aa.id
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	WHERE ai.institution=0 AND
	aa.email LIKE '%\.za'
)

----- Then we add the affiliation associations for the new affiliations:
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Argentina',307);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Australia',30);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Austria',21);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Bangladesh',989);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Belgium',211);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Brazil',207);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Bulgaria',1823);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Canada',9);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Catalonia',76);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Chile',560);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: China',141);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Colombia',345);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Croatia',668);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Cyprus',3441);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Czechia',25);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Denmark',782);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Estonia',3407);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Finland',86);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: France',15);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Germany',18);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Ghana',609);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Greece',361);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Hong Kong',141);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Hungary',353);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: India',72);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Indonesia',604);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Iran',118);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Ireland',87);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Israel',22);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Italy',541);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Japan',238);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Luxembourg',43);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Macau',1897);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Malaysia',4);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Mexico',786);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Netherlands',127);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: New Zealand',736);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Norway',217);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Poland',125);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Portugal',190);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Qatar',1618);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Romania',148);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Russia',83);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Saudi Arabia',728);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Singapore',1);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Slovenia',354);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: South Africa',287);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: South Korea',579);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Spain',76);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Sweden',74);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Switzerland',320);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Taiwan',119);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Turkey',651);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: Ukraine',6477);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: United Arab Emirates',3379);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: United Kingdom',31);
INSERT INTO affiliation_institutions (affiliation, institution) VALUES ('EMAIL INFERENCE: United States',7);

---Fixing journal names
UPDATE publications SET journal='G3' WHERE journal LIKE 'G3%';

UPDATE publications SET journal='Proceedings of the Royal Society B: Biological Sciences' WHERE journal='Proceedings B';

UPDATE publications SET journal='Proceedings of the Royal Society B: Biological Sciences' WHERE journal='Proceedings. Biological Sciences';

UPDATE publications SET journal='PNAS' WHERE journal='Proceedings Of The National Academy Of Sciences Of The United States Of America';

UPDATE publications SET journal='Philosophical Transactions B' WHERE LOWER(journal)=LOWER('PHILOSOPHICAL TRANSACTIONS OF THE ROYAL SOCIETY B: BIOLOGICAL SCIENCES');

UPDATE publications SET journal='Philosophical Transactions B' WHERE LOWER(journal)=LOWER('Philosophical Transactions Of The Royal Society Of London. Series B, Biological Sciences');

UPDATE publications SET journal='Philosophical Transactions A' WHERE LOWER(journal) LIKE LOWER('Philosophical Transactions of the Royal Society A: Mathematical%');

-- Capitalization problems
UPDATE publications SET journal='American Journal of Botany' WHERE LOWER(journal)=LOWER('American Journal of Botany');
UPDATE publications SET journal='American Journal of Human Genetics' WHERE LOWER(journal)=LOWER('American Journal of Human Genetics');
UPDATE publications SET journal='Annals of Botany' WHERE LOWER(journal)=LOWER('Annals of Botany');
UPDATE publications SET journal='Annals of the Rheumatic Diseases' WHERE LOWER(journal)=LOWER('Annals of the Rheumatic Diseases');
UPDATE publications SET journal='Antimicrobial Agents and Chemotherapy' WHERE LOWER(journal)=LOWER('Antimicrobial Agents and Chemotherapy');
UPDATE publications SET journal='Applied and Environmental Microbiology' WHERE LOWER(journal)=LOWER('Applied and Environmental Microbiology');
UPDATE publications SET journal='bioTROPICA' WHERE LOWER(journal)=LOWER('bioTROPICA');
UPDATE publications SET journal='Briefings in Bioinformatics' WHERE LOWER(journal)=LOWER('Briefings in Bioinformatics');
UPDATE publications SET journal='Briefings In Functional Genomics' WHERE LOWER(journal)=LOWER('Briefings In Functional Genomics');
UPDATE publications SET journal='Current Opinion in Neurobiology' WHERE LOWER(journal)=LOWER('Current Opinion in Neurobiology');
UPDATE publications SET journal='Development Genes and Evolution' WHERE LOWER(journal)=LOWER('Development Genes and Evolution');
UPDATE publications SET journal='DNA Research' WHERE LOWER(journal)=LOWER('DNA Research');
UPDATE publications SET journal='Ecology and Evolution' WHERE LOWER(journal)=LOWER('Ecology and Evolution');
UPDATE publications SET journal='eLife' WHERE LOWER(journal)=LOWER('eLife');
UPDATE publications SET journal='EMBO reports' WHERE LOWER(journal)=LOWER('EMBO reports');
UPDATE publications SET journal='eneuro' WHERE LOWER(journal)=LOWER('eneuro');
UPDATE publications SET journal='European Journal of Human Genetics' WHERE LOWER(journal)=LOWER('European Journal of Human Genetics');
UPDATE publications SET journal='Frontiers in Genetics' WHERE LOWER(journal)=LOWER('Frontiers in Genetics');
UPDATE publications SET journal='Frontiers in Immunology' WHERE LOWER(journal)=LOWER('Frontiers in Immunology');
UPDATE publications SET journal='Frontiers in Neural Circuits' WHERE LOWER(journal)=LOWER('Frontiers in Neural Circuits');
UPDATE publications SET journal='Frontiers in Neuroanatomy' WHERE LOWER(journal)=LOWER('Frontiers in Neuroanatomy');
UPDATE publications SET journal='Frontiers in Neurology' WHERE LOWER(journal)=LOWER('Frontiers in Neurology');
UPDATE publications SET journal='genesis' WHERE LOWER(journal)=LOWER('genesis');
UPDATE publications SET journal='Genetics in Medicine' WHERE LOWER(journal)=LOWER('Genetics in Medicine');
UPDATE publications SET journal='Genome Biology and Evolution' WHERE LOWER(journal)=LOWER('Genome Biology and Evolution');
UPDATE publications SET journal='Hormones and Behavior' WHERE LOWER(journal)=LOWER('Hormones and Behavior');
UPDATE publications SET journal='IEEE/ACM Transactions on Computational Biology and Bioinformatics' WHERE LOWER(journal)=LOWER('IEEE/ACM Transactions on Computational Biology and Bioinformatics');
UPDATE publications SET journal='International Journal of Antimicrobial Agents' WHERE LOWER(journal)=LOWER('International Journal of Antimicrobial Agents');
UPDATE publications SET journal='International Journal of Epidemiology' WHERE LOWER(journal)=LOWER('International Journal of Epidemiology');
UPDATE publications SET journal='iScience' WHERE LOWER(journal)=LOWER('iScience');
UPDATE publications SET journal='Journal of Alzheimer''s Disease' WHERE LOWER(journal)=LOWER('Journal of Alzheimer''s Disease');
UPDATE publications SET journal='Journal of Antimicrobial Chemotherapy' WHERE LOWER(journal)=LOWER('Journal of Antimicrobial Chemotherapy');
UPDATE publications SET journal='Journal of Bacteriology' WHERE LOWER(journal)=LOWER('Journal of Bacteriology');
UPDATE publications SET journal='Journal of Biomechanics' WHERE LOWER(journal)=LOWER('Journal of Biomechanics');
UPDATE publications SET journal='Journal of Cell Science' WHERE LOWER(journal)=LOWER('Journal of Cell Science');
UPDATE publications SET journal='Journal Of Chemical Ecology' WHERE LOWER(journal)=LOWER('Journal Of Chemical Ecology');
UPDATE publications SET journal='Journal of Chemical Information and Modeling' WHERE LOWER(journal)=LOWER('Journal of Chemical Information and Modeling');
UPDATE publications SET journal='Journal of Chemical Theory and Computation' WHERE LOWER(journal)=LOWER('Journal of Chemical Theory and Computation');
UPDATE publications SET journal='Journal of Cognitive Neuroscience' WHERE LOWER(journal)=LOWER('Journal of Cognitive Neuroscience');
UPDATE publications SET journal='Journal of Computational Biology' WHERE LOWER(journal)=LOWER('Journal of Computational Biology');
UPDATE publications SET journal='Journal of Computational Chemistry' WHERE LOWER(journal)=LOWER('Journal of Computational Chemistry');
UPDATE publications SET journal='Journal of Computational Neuroscience' WHERE LOWER(journal)=LOWER('Journal of Computational Neuroscience');
UPDATE publications SET journal='Journal of Computer-Aided Molecular Design' WHERE LOWER(journal)=LOWER('Journal of Computer-Aided Molecular Design');
UPDATE publications SET journal='Journal of Economic Entomology' WHERE LOWER(journal)=LOWER('Journal of Economic Entomology');
UPDATE publications SET journal='Journal of Experimental Botany' WHERE LOWER(journal)=LOWER('Journal of Experimental Botany');
UPDATE publications SET journal='Journal Of Genetics' WHERE LOWER(journal)=LOWER('Journal Of Genetics');
UPDATE publications SET journal='Journal of Molecular Biology' WHERE LOWER(journal)=LOWER('Journal of Molecular Biology');
UPDATE publications SET journal='Journal of Neuroscience Methods' WHERE LOWER(journal)=LOWER('Journal of Neuroscience Methods');
UPDATE publications SET journal='Journal of Neuroscience' WHERE LOWER(journal)=LOWER('Journal of Neuroscience');
UPDATE publications SET journal='Journal of Proteome Research' WHERE LOWER(journal)=LOWER('Journal of Proteome Research');
UPDATE publications SET journal='Journal of Structural Biology' WHERE LOWER(journal)=LOWER('Journal of Structural Biology');
UPDATE publications SET journal='Journal of the American Society for Mass Spectrometry' WHERE LOWER(journal)=LOWER('Journal of the American Society for Mass Spectrometry');
UPDATE publications SET journal='Journal of The Royal Society Interface' WHERE LOWER(journal)=LOWER('Journal of The Royal Society Interface');
UPDATE publications SET journal='Journal of Theoretical Biology' WHERE LOWER(journal)=LOWER('Journal of Theoretical Biology');
UPDATE publications SET journal='Journal of Virology' WHERE LOWER(journal)=LOWER('Journal of Virology');
UPDATE publications SET journal='Journal of Vision' WHERE LOWER(journal)=LOWER('Journal of Vision');
UPDATE publications SET journal='Lab on a Chip' WHERE LOWER(journal)=LOWER('Lab on a Chip');
UPDATE publications SET journal='mBio' WHERE LOWER(journal)=LOWER('mBio');
UPDATE publications SET journal='Methods in Molecular Biology' WHERE LOWER(journal)=LOWER('Methods in Molecular Biology');
UPDATE publications SET journal='Molecular Biology and Evolution' WHERE LOWER(journal)=LOWER('Molecular Biology and Evolution');
UPDATE publications SET journal='Molecular Biology of the Cell' WHERE LOWER(journal)=LOWER('Molecular Biology of the Cell');
UPDATE publications SET journal='Molecular Phylogenetics and Evolution' WHERE LOWER(journal)=LOWER('Molecular Phylogenetics and Evolution');
UPDATE publications SET journal='mSphere' WHERE LOWER(journal)=LOWER('mSphere');
UPDATE publications SET journal='mSystems' WHERE LOWER(journal)=LOWER('mSystems');
UPDATE publications SET journal='Neurobiology of Disease' WHERE LOWER(journal)=LOWER('Neurobiology of Disease');
UPDATE publications SET journal='NeuroToxicology' WHERE LOWER(journal)=LOWER('NeuroToxicology');
UPDATE publications SET journal='Orphanet Journal of Rare Diseases' WHERE LOWER(journal)=LOWER('Orphanet Journal of Rare Diseases');
UPDATE publications SET journal='PAIN' WHERE LOWER(journal)=LOWER('PAIN');
UPDATE publications SET journal='PLOS Computational Biology' WHERE LOWER(journal)=LOWER('PLOS Computational Biology');
UPDATE publications SET journal='PLOS Currents' WHERE LOWER(journal)=LOWER('PLOS Currents');
UPDATE publications SET journal='PLOS Genetics' WHERE LOWER(journal)=LOWER('PLOS Genetics');
UPDATE publications SET journal='PLOS ONE' WHERE LOWER(journal)=LOWER('PLOS ONE');
UPDATE publications SET journal='Proceedings of the Royal Society B: Biological Sciences' WHERE LOWER(journal)=LOWER('Proceedings of the Royal Society B: Biological Sciences');
UPDATE publications SET journal='Progress in Biophysics and Molecular Biology' WHERE LOWER(journal)=LOWER('Progress in Biophysics and Molecular Biology');
UPDATE publications SET journal='PROTEOMICS' WHERE LOWER(journal)=LOWER('PROTEOMICS');
UPDATE publications SET journal='Respiratory Research' WHERE LOWER(journal)=LOWER('Respiratory Research');
UPDATE publications SET journal='Royal Society Open Science' WHERE LOWER(journal)=LOWER('Royal Society Open Science');
UPDATE publications SET journal='Science of The Total Environment' WHERE LOWER(journal)=LOWER('Science of The Total Environment');
UPDATE publications SET journal='Social Cognitive and Affective Neuroscience' WHERE LOWER(journal)=LOWER('Social Cognitive and Affective Neuroscience');
UPDATE publications SET journal='Statistical Applications in Genetics and Molecular Biology' WHERE LOWER(journal)=LOWER('Statistical Applications in Genetics and Molecular Biology');
UPDATE publications SET journal='Statistical Methods in Medical Research' WHERE LOWER(journal)=LOWER('Statistical Methods in Medical Research');
UPDATE publications SET journal='STEM CELLS' WHERE LOWER(journal)=LOWER('STEM CELLS');
UPDATE publications SET journal='The Journal of Cell Biology' WHERE LOWER(journal)=LOWER('The Journal of Cell Biology');
UPDATE publications SET journal='The Journal of Experimental Biology' WHERE LOWER(journal)=LOWER('The Journal of Experimental Biology');
UPDATE publications SET journal='The Journal of Neuroscience' WHERE LOWER(journal)=LOWER('The Journal of Neuroscience');
UPDATE publications SET journal='The Journal of Physical Chemistry B' WHERE LOWER(journal)=LOWER('The Journal of Physical Chemistry B');
UPDATE publications SET journal='Theoretical and Applied Genetics' WHERE LOWER(journal)=LOWER('Theoretical and Applied Genetics');
UPDATE publications SET journal='Theory in Biosciences' WHERE LOWER(journal)=LOWER('Theory in Biosciences');
UPDATE publications SET journal='Twin Research and Human Genetics' WHERE LOWER(journal)=LOWER('Twin Research and Human Genetics');

-- Some journals appear with and without a leading "The ":
UPDATE publications SET journal='American Journal of Human Genetics' WHERE journal='The American Journal of Human Genetics';
UPDATE publications SET journal='Annals of Applied Statistics' WHERE journal='The Annals of Applied Statistics';
UPDATE publications SET journal='International Journal of Developmental Biology' WHERE journal='The International Journal of Developmental Biology';
UPDATE publications SET journal='International Journal of Infectious Diseases' WHERE journal='The International Journal of Infectious Diseases';
UPDATE publications SET journal='Journal of Cell Biology' WHERE journal='The Journal of Cell Biology';
UPDATE publications SET journal='Journal of Clinical Investigation' WHERE journal='The Journal of Clinical Investigation';
UPDATE publications SET journal='Journal of Comparative Neurology' WHERE journal='The Journal of Comparative Neurology';
UPDATE publications SET journal='Journal of Eukaryotic Microbiology' WHERE journal='The Journal of Eukaryotic Microbiology';
UPDATE publications SET journal='Journal of Experimental Biology' WHERE journal='The Journal of Experimental Biology';
UPDATE publications SET journal='Journal of Experimental Medicine' WHERE journal='The Journal of Experimental Medicine';
UPDATE publications SET journal='Journal of General Physiology' WHERE journal='The Journal of General Physiology';
UPDATE publications SET journal='Journal of Infectious Diseases' WHERE journal='The Journal of Infectious Diseases';
UPDATE publications SET journal='Journal of Neuroscience' WHERE journal='The Journal of Neuroscience';
UPDATE publications SET journal='Journal of Open Source Software' WHERE journal='The Journal of Open Source Software';
UPDATE publications SET journal='New Phytologist' WHERE journal='The New Phytologist';