-- Backfill family_members.gender from the first word of firstname.
-- Names come from supabase/seed/first_name_gender.csv. Unknown (unisex) names are
-- stored with gender NULL so they are marked as reviewed but never applied.
-- Only rows with gender NULL are updated; safe to re-run after adding more names.
-- Run in the Supabase SQL editor.

create table if not exists first_name_gender (
  name text primary key,
  gender text check (gender in ('Male', 'Female'))
);

insert into first_name_gender (name, gender) values
  ('JOHN', 'Male'),
  ('MARY', 'Female'),
  ('MARK', 'Male'),
  ('PRINCESS', 'Female'),
  ('JHON', 'Male'),
  ('JAMES', 'Male'),
  ('CHRISTIAN', 'Male'),
  ('ANGEL', 'Unknown'),
  ('MARIA', 'Female'),
  ('MICHAEL', 'Male'),
  ('PRINCE', 'Male'),
  ('REY', 'Unknown'),
  ('JOEL', 'Male'),
  ('KENT', 'Male'),
  ('MA.', 'Female'),
  ('MA', 'Female'),
  ('APRIL', 'Female'),
  ('JOCELYN', 'Female'),
  ('RYAN', 'Male'),
  ('JOSEPH', 'Male'),
  ('RHEA', 'Female'),
  ('JAY', 'Unknown'),
  ('JESSA', 'Female'),
  ('JOSHUA', 'Male'),
  ('DANIEL', 'Male'),
  ('CHRISTINE', 'Female'),
  ('RICHARD', 'Male'),
  ('ROMEO', 'Male'),
  ('JERRY', 'Male'),
  ('ARNEL', 'Male'),
  ('EVELYN', 'Female'),
  ('ROLANDO', 'Male'),
  ('JOSE', 'Male'),
  ('ALTHEA', 'Female'),
  ('DANILO', 'Male'),
  ('IAN', 'Male'),
  ('REYNALDO', 'Male'),
  ('ROBERT', 'Male'),
  ('JOSEPHINE', 'Female'),
  ('ARIEL', 'Unknown'),
  ('ANTONIO', 'Male'),
  ('NOEL', 'Male'),
  ('JONATHAN', 'Male'),
  ('JUSTINE', 'Unknown'),
  ('RONALD', 'Male'),
  ('ROGER', 'Male'),
  ('CHERRY', 'Female'),
  ('JEAN', 'Unknown'),
  ('MARICEL', 'Female'),
  ('GINA', 'Female'),
  ('RENE', 'Unknown'),
  ('JESSIE', 'Unknown'),
  ('EDWIN', 'Male'),
  ('ROGELIO', 'Male'),
  ('FRANCIS', 'Male'),
  ('JEFFREY', 'Male'),
  ('JAN', 'Unknown'),
  ('ANGELO', 'Male'),
  ('PRECIOUS', 'Female'),
  ('EDUARDO', 'Male'),
  ('KIM', 'Unknown'),
  ('VINCENT', 'Male'),
  ('RICKY', 'Male'),
  ('JIMMY', 'Male'),
  ('ANALYN', 'Female'),
  ('IVAN', 'Male'),
  ('MICHELLE', 'Female'),
  ('KYLE', 'Unknown'),
  ('IVY', 'Female'),
  ('MARVIN', 'Male'),
  ('CARL', 'Male'),
  ('JULIE', 'Female'),
  ('LOVELY', 'Female'),
  ('CHRISTOPHER', 'Male'),
  ('JENNY', 'Female'),
  ('KENNETH', 'Male'),
  ('ALLAN', 'Male'),
  ('JOAN', 'Female'),
  ('JUDY', 'Female'),
  ('HAZEL', 'Female'),
  ('HELEN', 'Female'),
  ('MARLON', 'Male'),
  ('DAVE', 'Male'),
  ('TERESITA', 'Female'),
  ('MERLYN', 'Female'),
  ('ALVIN', 'Male'),
  ('ELMER', 'Male'),
  ('SOPHIA', 'Female'),
  ('JENELYN', 'Female'),
  ('RANDY', 'Male'),
  ('JOVELYN', 'Female'),
  ('ASHLEY', 'Unknown'),
  ('GRACE', 'Female'),
  ('ANTHONY', 'Male'),
  ('ROY', 'Male'),
  ('ROBERTO', 'Male'),
  ('JAYSON', 'Male'),
  ('LEONARDO', 'Male'),
  ('FELIX', 'Male'),
  ('CHRIS', 'Unknown'),
  ('GEMMA', 'Female'),
  ('ALEXANDER', 'Male'),
  ('GERALD', 'Male'),
  ('SAMUEL', 'Male'),
  ('NATHANIEL', 'Male'),
  ('ARNOLD', 'Male'),
  ('JULIUS', 'Male'),
  ('FRANCISCO', 'Male'),
  ('RONEL', 'Male'),
  ('FERNANDO', 'Male'),
  ('EDGAR', 'Male'),
  ('BRYAN', 'Male'),
  ('GILBERT', 'Male'),
  ('MARIO', 'Male'),
  ('RUBEN', 'Male'),
  ('RICO', 'Male'),
  ('JEROME', 'Male'),
  ('PAUL', 'Male'),
  ('RICARDO', 'Male'),
  ('ROMEL', 'Male'),
  ('ERWIN', 'Male'),
  ('ERNESTO', 'Male'),
  ('EDDIE', 'Male'),
  ('ALFREDO', 'Male'),
  ('RODEL', 'Male'),
  ('ALBERT', 'Male'),
  ('RENANTE', 'Male'),
  ('VINCE', 'Male'),
  ('REX', 'Male'),
  ('WILFREDO', 'Male'),
  ('CARLITO', 'Male'),
  ('ARMANDO', 'Male'),
  ('DENNIS', 'Male'),
  ('RODRIGO', 'Male'),
  ('NEIL', 'Male'),
  ('DANNY', 'Male'),
  ('RENATO', 'Male'),
  ('CHARLES', 'Male'),
  ('JUNREY', 'Male'),
  ('ROEL', 'Male'),
  ('ALBERTO', 'Male'),
  ('CLARK', 'Male'),
  ('REYMARK', 'Male'),
  ('ROLAND', 'Male'),
  ('KURT', 'Male'),
  ('VICENTE', 'Male'),
  ('MARJUN', 'Male'),
  ('DEXTER', 'Male'),
  ('RODOLFO', 'Male'),
  ('MIKE', 'Male'),
  ('PEDRO', 'Male'),
  ('GLENN', 'Male'),
  ('ROLLY', 'Male'),
  ('JOHNNY', 'Male'),
  ('NELSON', 'Male'),
  ('JUSTIN', 'Male'),
  ('GABRIEL', 'Male'),
  ('STEPHEN', 'Male'),
  ('JASON', 'Male'),
  ('RONNIE', 'Male'),
  ('ADRIAN', 'Male'),
  ('ERIC', 'Male'),
  ('RAMIL', 'Male'),
  ('EMMANUEL', 'Male'),
  ('ETHAN', 'Male'),
  ('LOUIE', 'Male'),
  ('KEVIN', 'Male'),
  ('RALPH', 'Male'),
  ('ROMMEL', 'Male'),
  ('KIAN', 'Male'),
  ('WILLIAM', 'Male'),
  ('MARC', 'Male'),
  ('JAIME', 'Male'),
  ('KING', 'Male'),
  ('EFREN', 'Male'),
  ('ERNIE', 'Male'),
  ('JULITO', 'Male'),
  ('BRIAN', 'Male'),
  ('NESTOR', 'Male'),
  ('JERALD', 'Male'),
  ('CLINT', 'Male'),
  ('MELVIN', 'Male'),
  ('RENZ', 'Male'),
  ('LIAM', 'Male'),
  ('JAKE', 'Male'),
  ('NIÑO', 'Male'),
  ('DOMINADOR', 'Male'),
  ('RAMEL', 'Male'),
  ('RAUL', 'Male'),
  ('LEO', 'Male'),
  ('BENJAMIN', 'Male'),
  ('JERSON', 'Male'),
  ('ARGIE', 'Male'),
  ('RAYMOND', 'Male'),
  ('ALEJANDRO', 'Male'),
  ('CESAR', 'Male'),
  ('EARL', 'Male'),
  ('NATHAN', 'Male'),
  ('JUANITO', 'Male'),
  ('JESUS', 'Male'),
  ('DARWIN', 'Male'),
  ('JOEY', 'Male'),
  ('HAROLD', 'Male'),
  ('MANUEL', 'Male'),
  ('VICTOR', 'Male'),
  ('RUDY', 'Male'),
  ('ARJAY', 'Male'),
  ('DANTE', 'Male'),
  ('HENRY', 'Male'),
  ('GEORGE', 'Male'),
  ('JOEMAR', 'Male'),
  ('EDGARDO', 'Male'),
  ('REYMOND', 'Male'),
  ('BENJIE', 'Male'),
  ('JERIC', 'Male'),
  ('NIEL', 'Male'),
  ('JAY-AR', 'Male'),
  ('ACE', 'Male'),
  ('CARLO', 'Male'),
  ('RAFAEL', 'Male'),
  ('JASPER', 'Male'),
  ('GIAN', 'Male'),
  ('PETER', 'Male'),
  ('FELIPE', 'Male'),
  ('SEAN', 'Male'),
  ('JOMAR', 'Male'),
  ('DARYL', 'Male'),
  ('PHILIP', 'Male'),
  ('RONILO', 'Male'),
  ('REGIE', 'Male'),
  ('EUGENE', 'Male'),
  ('KHENT', 'Male'),
  ('ROMNICK', 'Male'),
  ('BONIFACIO', 'Male'),
  ('LARRY', 'Male'),
  ('LANCE', 'Male'),
  ('ZIAN', 'Male'),
  ('RAMON', 'Male'),
  ('ROLDAN', 'Male'),
  ('SHERWIN', 'Male'),
  ('JOVEN', 'Male'),
  ('JONEL', 'Male'),
  ('JACOB', 'Male'),
  ('MELCHOR', 'Male'),
  ('MATT', 'Male'),
  ('ROMULO', 'Male'),
  ('DAN', 'Male'),
  ('WILSON', 'Male'),
  ('OLIVER', 'Male'),
  ('JERWIN', 'Male'),
  ('KEN', 'Male'),
  ('CLARENCE', 'Male'),
  ('TRISTAN', 'Male'),
  ('JUAN', 'Male'),
  ('JULIETO', 'Male'),
  ('ZION', 'Male'),
  ('VIRGILIO', 'Male'),
  ('FRANKLIN', 'Male'),
  ('ANGELITO', 'Male'),
  ('DAVID', 'Male'),
  ('DOMINGO', 'Male'),
  ('GREGORIO', 'Male'),
  ('KLENT', 'Male'),
  ('DIOSDADO', 'Male'),
  ('JARED', 'Male'),
  ('ARCHIE', 'Male'),
  ('LEONARD', 'Male'),
  ('KARL', 'Male'),
  ('CELSO', 'Male'),
  ('ALJUN', 'Male'),
  ('JESON', 'Male'),
  ('EZEKIEL', 'Male'),
  ('CRISTIAN', 'Male'),
  ('CYRUS', 'Male'),
  ('RENIEL', 'Male'),
  ('BRYLLE', 'Male'),
  ('JUMAR', 'Male'),
  ('WARREN', 'Male'),
  ('SERGIO', 'Male'),
  ('BERNIE', 'Male'),
  ('DIONESIO', 'Male'),
  ('AXEL', 'Male'),
  ('KIETH', 'Male'),
  ('WILLY', 'Male'),
  ('REYNALD', 'Male'),
  ('REYNAN', 'Male'),
  ('CLIFFORD', 'Male'),
  ('CLYDE', 'Male'),
  ('KENTH', 'Male'),
  ('LAURENCE', 'Male'),
  ('SANNY', 'Male'),
  ('JAYDEN', 'Male'),
  ('ALJON', 'Male'),
  ('STEVEN', 'Male'),
  ('PATRICK', 'Male'),
  ('ALLEN', 'Male'),
  ('CARLOS', 'Male'),
  ('ABDUL', 'Male'),
  ('OSCAR', 'Male'),
  ('ELVIN', 'Male'),
  ('JERICK', 'Male'),
  ('MIGUEL', 'Male'),
  ('KEITH', 'Male'),
  ('JERICHO', 'Male'),
  ('GLEN', 'Male'),
  ('BERNARD', 'Male'),
  ('AARON', 'Male'),
  ('FRANK', 'Male'),
  ('LITO', 'Male'),
  ('RODULFO', 'Male'),
  ('JOSH', 'Male'),
  ('ARTHUR', 'Male'),
  ('CRISANTO', 'Male'),
  ('REYNANTE', 'Male'),
  ('GERRY', 'Male'),
  ('LEMUEL', 'Male'),
  ('RAY', 'Male'),
  ('JOE', 'Male'),
  ('AUSTIN', 'Male'),
  ('CYRIL', 'Male'),
  ('LORETO', 'Male'),
  ('RONNEL', 'Male'),
  ('JEFF', 'Male'),
  ('GARRY', 'Male'),
  ('ARMAN', 'Male'),
  ('ANDY', 'Male'),
  ('JIMBOY', 'Male'),
  ('LLOYD', 'Male'),
  ('JULIAN', 'Male'),
  ('JOSELITO', 'Male'),
  ('HARVEY', 'Male'),
  ('JHONNY', 'Male'),
  ('BOBBY', 'Male'),
  ('BERNABE', 'Male'),
  ('JEMUEL', 'Male'),
  ('JORGE', 'Male'),
  ('EJAY', 'Male'),
  ('JEFFERSON', 'Male'),
  ('BRENT', 'Male'),
  ('JOVAN', 'Male'),
  ('TEODORO', 'Male'),
  ('SALVADOR', 'Male'),
  ('JUNEL', 'Male'),
  ('ASHER', 'Male'),
  ('ISIDRO', 'Male'),
  ('ALDRIN', 'Male'),
  ('ARTEMIO', 'Male'),
  ('HARRY', 'Male'),
  ('LAWRENCE', 'Male'),
  ('EDISON', 'Male'),
  ('ARVIN', 'Male'),
  ('ALDREN', 'Male'),
  ('NICK', 'Male'),
  ('DWAYNE', 'Male'),
  ('AGUSTIN', 'Male'),
  ('MAXIMO', 'Male'),
  ('LESTER', 'Male'),
  ('RAFFY', 'Male'),
  ('JOHNREY', 'Male'),
  ('EDRIAN', 'Male'),
  ('KHIAN', 'Male'),
  ('MAC', 'Male'),
  ('ZACH', 'Male'),
  ('ORLANDO', 'Male'),
  ('RUFINO', 'Male'),
  ('RENAN', 'Male'),
  ('JOBERT', 'Male'),
  ('MARVEN', 'Male'),
  ('NILO', 'Male'),
  ('JONARD', 'Male'),
  ('SATURNINO', 'Male'),
  ('JOVANIE', 'Male'),
  ('ROWEL', 'Male'),
  ('ANDRES', 'Male'),
  ('JACK', 'Male'),
  ('MARCELO', 'Male'),
  ('MATTHEW', 'Male'),
  ('PAULINO', 'Male'),
  ('REYMART', 'Male'),
  ('LORENZO', 'Male'),
  ('JONAS', 'Male'),
  ('NASH', 'Male'),
  ('PABLITO', 'Male'),
  ('RUSSEL', 'Male'),
  ('LUKE', 'Male'),
  ('NORBERTO', 'Male'),
  ('RODELIO', 'Male'),
  ('ALDEN', 'Male'),
  ('JHUN', 'Male'),
  ('RONALDO', 'Male'),
  ('ARNIE', 'Male'),
  ('ELIAS', 'Male'),
  ('JESSON', 'Male'),
  ('FEDERICO', 'Male'),
  ('JEMAR', 'Male'),
  ('RAYMUND', 'Male'),
  ('MARCELINO', 'Male'),
  ('ANDREW', 'Male'),
  ('PABLO', 'Male'),
  ('TITO', 'Male'),
  ('DIEGO', 'Male'),
  ('DOMINIC', 'Male'),
  ('HANZ', 'Male'),
  ('SAMSON', 'Male'),
  ('NICOLAS', 'Male'),
  ('NORMAN', 'Male'),
  ('ALJOHN', 'Male'),
  ('GUILLERMO', 'Male'),
  ('JORDAN', 'Male'),
  ('ARNIEL', 'Male'),
  ('ROMIE', 'Male'),
  ('JOHNY', 'Male'),
  ('KIER', 'Male'),
  ('AIDEN', 'Male'),
  ('EDWARD', 'Male'),
  ('NICO', 'Male'),
  ('RIC', 'Male'),
  ('CERILO', 'Male'),
  ('TERRENCE', 'Male'),
  ('BERNARDO', 'Male'),
  ('LEVI', 'Male'),
  ('FRANZ', 'Male'),
  ('ALMER', 'Male'),
  ('FLORENCIO', 'Male'),
  ('JAYMAR', 'Male'),
  ('ZACK', 'Male'),
  ('DONALD', 'Male'),
  ('ZACHARY', 'Male'),
  ('LUIS', 'Male'),
  ('KIRK', 'Male'),
  ('JOEBERT', 'Male'),
  ('NARCISO', 'Male'),
  ('JAYPEE', 'Male'),
  ('RONIL', 'Male'),
  ('DYLAN', 'Male'),
  ('DINDO', 'Male'),
  ('ROQUE', 'Male'),
  ('PEPITO', 'Male'),
  ('BRYLE', 'Male'),
  ('MICHEAL', 'Male'),
  ('SETH', 'Male'),
  ('JAPHET', 'Male'),
  ('LUCAS', 'Male'),
  ('RAYMART', 'Male'),
  ('MATEO', 'Male'),
  ('JEFFRY', 'Male'),
  ('DWIGHT', 'Male'),
  ('ROSENDO', 'Male'),
  ('FELICIANO', 'Male'),
  ('CAMILO', 'Male'),
  ('LEOPOLDO', 'Male'),
  ('RYLE', 'Male'),
  ('BILLY', 'Male'),
  ('JAYMARK', 'Male'),
  ('WARLITO', 'Male'),
  ('HEZEKIAH', 'Male'),
  ('JIM', 'Male'),
  ('MARCO', 'Male'),
  ('JUNRIEL', 'Male'),
  ('PATRICIO', 'Male'),
  ('ARTURO', 'Male'),
  ('VICTORIANO', 'Male'),
  ('JEREMY', 'Male'),
  ('AZRIEL', 'Male'),
  ('JUNMAR', 'Male'),
  ('ARJIE', 'Male'),
  ('ZALDY', 'Male'),
  ('REMARK', 'Male'),
  ('MAR', 'Male'),
  ('MARJON', 'Male'),
  ('KENETH', 'Male'),
  ('BIENVENIDO', 'Male'),
  ('FREDERICK', 'Male'),
  ('ANDREI', 'Male'),
  ('BRAYAN', 'Male'),
  ('VIC', 'Male'),
  ('MARLO', 'Male'),
  ('RODERICK', 'Male'),
  ('JONAH', 'Male'),
  ('ROLAN', 'Male'),
  ('STEVE', 'Male'),
  ('JESTONI', 'Male'),
  ('DARIO', 'Male'),
  ('CALVIN', 'Male'),
  ('JAIRUS', 'Male'),
  ('GAVIN', 'Male'),
  ('BEN', 'Male'),
  ('MOISES', 'Male'),
  ('CONRADO', 'Male'),
  ('JUNARD', 'Male'),
  ('ARNULFO', 'Male'),
  ('VENANCIO', 'Male'),
  ('KHYLE', 'Male'),
  ('GENEROSO', 'Male'),
  ('DALE', 'Male'),
  ('MARIANO', 'Male'),
  ('JEMBOY', 'Male'),
  ('ROBINSON', 'Male'),
  ('ADONIS', 'Male'),
  ('GERARDO', 'Male'),
  ('LORENZ', 'Male'),
  ('ALFONSO', 'Male'),
  ('JUDE', 'Male'),
  ('JAYLORD', 'Male'),
  ('DELFIN', 'Male'),
  ('EDSEL', 'Male'),
  ('MARCOS', 'Male'),
  ('EDILBERTO', 'Male'),
  ('MANNY', 'Male'),
  ('PAQUITO', 'Male'),
  ('RONELO', 'Male'),
  ('MILES', 'Male'),
  ('CHESTER', 'Male'),
  ('ELIJAH', 'Male'),
  ('REYNOLD', 'Male'),
  ('ARSENIO', 'Male'),
  ('LOLITO', 'Male'),
  ('BENEDICTO', 'Male'),
  ('SHAWN', 'Male'),
  ('RICHIE', 'Male'),
  ('JERICO', 'Male'),
  ('JON', 'Male'),
  ('WILBERT', 'Male'),
  ('EZRA', 'Male'),
  ('ANDREY', 'Male'),
  ('CRISPIN', 'Male'),
  ('GERONIMO', 'Male'),
  ('IRENEO', 'Male'),
  ('RONIEL', 'Male'),
  ('NOAH', 'Male'),
  ('KENDRICK', 'Male'),
  ('MOHAMMAD', 'Male'),
  ('EUGENIO', 'Male'),
  ('TROY', 'Male'),
  ('JEFREY', 'Male'),
  ('CIRILO', 'Male'),
  ('ABUNDIO', 'Male'),
  ('ROMY', 'Male'),
  ('JASPHER', 'Male'),
  ('RANEL', 'Male'),
  ('KEAN', 'Male'),
  ('RAM', 'Male'),
  ('CLENT', 'Male'),
  ('JAMEL', 'Male'),
  ('CEDRIC', 'Male'),
  ('JULIO', 'Male'),
  ('WILMER', 'Male'),
  ('TEOFILO', 'Male'),
  ('RANIEL', 'Male'),
  ('ELIEZER', 'Male'),
  ('ANTON', 'Male'),
  ('RENEBOY', 'Male'),
  ('JHONREY', 'Male'),
  ('SAMMY', 'Male'),
  ('ALGENE', 'Male'),
  ('JEREMIAS', 'Male'),
  ('ISAIAH', 'Male'),
  ('CHARLITO', 'Male'),
  ('JOVERT', 'Male'),
  ('JEMARK', 'Male'),
  ('RENIER', 'Male'),
  ('NOLI', 'Male'),
  ('RAMONITO', 'Male'),
  ('REDEN', 'Male'),
  ('JOMEL', 'Male'),
  ('JED', 'Male'),
  ('ANDRE', 'Male'),
  ('JOELITO', 'Male'),
  ('NIKKO', 'Male'),
  ('KLINT', 'Male'),
  ('ELBERT', 'Male'),
  ('GIL', 'Male'),
  ('DAVEN', 'Male'),
  ('GIDEON', 'Male'),
  ('JONALD', 'Male'),
  ('NETHAN', 'Male'),
  ('XANDER', 'Male'),
  ('AXCEL', 'Male'),
  ('AVELINO', 'Male'),
  ('MARTIN', 'Male'),
  ('PATERNO', 'Male'),
  ('AMADO', 'Male'),
  ('ENRIQUE', 'Male'),
  ('JEREMIAH', 'Male'),
  ('MARJHON', 'Male'),
  ('HERMAN', 'Male'),
  ('ZOSIMO', 'Male'),
  ('ALFIE', 'Male'),
  ('MERVIN', 'Male'),
  ('SONNY', 'Male'),
  ('ISMAEL', 'Male'),
  ('EDMAR', 'Male'),
  ('FELIZARDO', 'Male'),
  ('KENN', 'Male'),
  ('ADAM', 'Male'),
  ('DIOSCORO', 'Male'),
  ('FREDDIE', 'Male'),
  ('ELPEDIO', 'Male'),
  ('OMAR', 'Male'),
  ('ALAN', 'Male'),
  ('GINO', 'Male'),
  ('JEBOY', 'Male'),
  ('SEVERINO', 'Male'),
  ('MATHEW', 'Male'),
  ('ALFRED', 'Male'),
  ('BRYCE', 'Male'),
  ('THEO', 'Male'),
  ('ARNOLFO', 'Male'),
  ('ZEUS', 'Male'),
  ('TIRSO', 'Male'),
  ('ALJUR', 'Male'),
  ('EMILIO', 'Male'),
  ('EUSEBIO', 'Male'),
  ('FERDINAND', 'Male'),
  ('JIMUEL', 'Male'),
  ('GARY', 'Male'),
  ('DIONISIO', 'Male'),
  ('CEDRICK', 'Male'),
  ('TYLER', 'Male'),
  ('RON', 'Male'),
  ('KENNY', 'Male'),
  ('RODNEY', 'Male'),
  ('JUNJUN', 'Male'),
  ('KHURT', 'Male'),
  ('MELBERT', 'Male'),
  ('SOLOMON', 'Male'),
  ('ZAYN', 'Male'),
  ('JUNNEL', 'Male'),
  ('ROCKY', 'Male'),
  ('ROMAR', 'Male'),
  ('VICTORINO', 'Male'),
  ('CRESENCIO', 'Male'),
  ('REYMAR', 'Male'),
  ('JHONEL', 'Male'),
  ('LINO', 'Male'),
  ('REYMON', 'Male'),
  ('REYMUND', 'Male'),
  ('JACINTO', 'Male'),
  ('DIETHER', 'Male'),
  ('JHONMARK', 'Male'),
  ('JAYVEE', 'Male'),
  ('EDUARD', 'Male'),
  ('DEMETRIO', 'Male'),
  ('DON', 'Male'),
  ('KHERT', 'Male'),
  ('ARJUN', 'Male'),
  ('AURELIO', 'Male'),
  ('MANOLITO', 'Male'),
  ('XYRUS', 'Male'),
  ('MARCIANO', 'Male'),
  ('ELMAR', 'Male'),
  ('LEONILO', 'Male'),
  ('ENRICO', 'Male'),
  ('WILMAR', 'Male'),
  ('SILVESTRE', 'Male'),
  ('ERLINDO', 'Male'),
  ('WINDEL', 'Male'),
  ('BENITO', 'Male'),
  ('WINSTON', 'Male'),
  ('HARVY', 'Male'),
  ('EDMUNDO', 'Male'),
  ('ARON', 'Male'),
  ('KIENTH', 'Male'),
  ('CERELO', 'Male'),
  ('KHARL', 'Male'),
  ('NICANOR', 'Male'),
  ('NICASIO', 'Male'),
  ('ZYRUS', 'Male'),
  ('KHAIZER', 'Male'),
  ('CELESTINO', 'Male'),
  ('ABNER', 'Male'),
  ('ROLLEN', 'Male'),
  ('ABRAHAM', 'Male'),
  ('JHONRIEL', 'Male'),
  ('CLINTON', 'Male'),
  ('EFRAIM', 'Male'),
  ('DENIS', 'Male'),
  ('CLAUDIO', 'Male'),
  ('RENJIE', 'Male'),
  ('JAIDEN', 'Male'),
  ('NIMROD', 'Male'),
  ('GODWIN', 'Male'),
  ('ASNOR', 'Male'),
  ('DENZEL', 'Male'),
  ('MARGARITO', 'Male'),
  ('RECHARD', 'Male'),
  ('JINO', 'Male'),
  ('TYRONE', 'Male'),
  ('CONSTANCIO', 'Male'),
  ('GREG', 'Male'),
  ('CORNELIO', 'Male'),
  ('SANTIAGO', 'Male'),
  ('REYAN', 'Male'),
  ('MELECIO', 'Male'),
  ('GUALBERTO', 'Male'),
  ('JESTER', 'Male'),
  ('ANECITO', 'Male'),
  ('ELEUTERIO', 'Male'),
  ('VICTORIO', 'Male'),
  ('CEASAR', 'Male'),
  ('ERICK', 'Male'),
  ('WALTER', 'Male'),
  ('ELIEZAR', 'Male'),
  ('RAYMUNDO', 'Male'),
  ('HANS', 'Male'),
  ('WENDELL', 'Male'),
  ('GIO', 'Male'),
  ('LUCIANO', 'Male'),
  ('SIMON', 'Male'),
  ('MIKKO', 'Male'),
  ('XAVIER', 'Male'),
  ('JOJO', 'Male'),
  ('ADRIEL', 'Male'),
  ('CEFERINO', 'Male'),
  ('HECTOR', 'Male'),
  ('JOMER', 'Male'),
  ('RHENZ', 'Male'),
  ('IRENIO', 'Male'),
  ('MODESTO', 'Male'),
  ('ALVEN', 'Male'),
  ('JONH', 'Male'),
  ('RANILO', 'Male'),
  ('ELTON', 'Male'),
  ('CRISTITO', 'Male'),
  ('LAURENCIO', 'Male'),
  ('ROWELL', 'Male'),
  ('FLORENTINO', 'Male'),
  ('CRISTOPHER', 'Male'),
  ('JERIEL', 'Male'),
  ('ELVIS', 'Male'),
  ('JOREN', 'Male'),
  ('ZAIJAN', 'Male'),
  ('REGINO', 'Male'),
  ('HERNANIE', 'Male'),
  ('LORENCE', 'Male'),
  ('ZAYNE', 'Male'),
  ('ZEKE', 'Male'),
  ('CATALINO', 'Male'),
  ('RALF', 'Male'),
  ('ESMAEL', 'Male'),
  ('ELDEN', 'Male'),
  ('LEONEL', 'Male'),
  ('JONIEL', 'Male'),
  ('EMELIO', 'Male'),
  ('AIVAN', 'Male'),
  ('CLEMENTE', 'Male'),
  ('RESTITUTO', 'Male'),
  ('APOLONIO', 'Male'),
  ('JASFER', 'Male'),
  ('ESMERALDO', 'Male'),
  ('CALIXTO', 'Male'),
  ('JAMAL', 'Male'),
  ('BENIGNO', 'Male'),
  ('TOMMY', 'Male'),
  ('HILARIO', 'Male'),
  ('TOMAS', 'Male'),
  ('FIDEL', 'Male'),
  ('REMEGIO', 'Male'),
  ('JHONDEL', 'Male'),
  ('JUNITO', 'Male'),
  ('GENARO', 'Male'),
  ('DENVER', 'Male'),
  ('ADRIANO', 'Male'),
  ('PAULO', 'Male'),
  ('NINO', 'Male'),
  ('RENZO', 'Male'),
  ('GODOFREDO', 'Male'),
  ('BALTAZAR', 'Male'),
  ('LYNDON', 'Male'),
  ('CALEB', 'Male'),
  ('MARBEN', 'Male'),
  ('NIGEL', 'Male'),
  ('RANIL', 'Male'),
  ('JONNEL', 'Male'),
  ('RENALDO', 'Male'),
  ('ZANE', 'Male'),
  ('EUTIQUIO', 'Male'),
  ('DRAKE', 'Male'),
  ('DIRK', 'Male'),
  ('ZAC', 'Male'),
  ('JOVENCIO', 'Male'),
  ('WENIFREDO', 'Male'),
  ('CURT', 'Male'),
  ('ZHIAN', 'Male'),
  ('NEMESIO', 'Male'),
  ('MARWIN', 'Male'),
  ('JACE', 'Male'),
  ('ORLAND', 'Male'),
  ('REMUEL', 'Male'),
  ('RHYLE', 'Male'),
  ('LUISITO', 'Male'),
  ('EMILIANO', 'Male'),
  ('RAYMARK', 'Male'),
  ('KAISER', 'Male'),
  ('MART', 'Male'),
  ('KAIZER', 'Male'),
  ('ALJHON', 'Male'),
  ('KENZO', 'Male'),
  ('VERGEL', 'Male'),
  ('RICHMOND', 'Male'),
  ('JOVITO', 'Male'),
  ('MIGUELITO', 'Male'),
  ('VENERANDO', 'Male'),
  ('DARWEN', 'Male'),
  ('ALDRICH', 'Male'),
  ('DARREN', 'Male'),
  ('ANDRIAN', 'Male'),
  ('JEFERSON', 'Male'),
  ('LOWEL', 'Male'),
  ('RUSSELL', 'Male'),
  ('WAYNE', 'Male'),
  ('BENEDICT', 'Male'),
  ('RHODEL', 'Male'),
  ('ANDRO', 'Male'),
  ('FRED', 'Male'),
  ('FERNAN', 'Male'),
  ('BERNALDO', 'Male'),
  ('QUIRINO', 'Male'),
  ('APOLINARIO', 'Male'),
  ('BENNY', 'Male'),
  ('LUCIO', 'Male'),
  ('PORFERIO', 'Male'),
  ('JAMESON', 'Male'),
  ('JETHRO', 'Male'),
  ('EVAN', 'Male'),
  ('PEDRITO', 'Male'),
  ('JOLITO', 'Male'),
  ('LOURENCE', 'Male'),
  ('FLORANTE', 'Male'),
  ('GERSON', 'Male'),
  ('JETRO', 'Male'),
  ('ARWIN', 'Male'),
  ('PONCIANO', 'Male'),
  ('CHANDLER', 'Male'),
  ('DINO', 'Male'),
  ('KLENTH', 'Male'),
  ('ABDULLAH', 'Male'),
  ('EPIFANIO', 'Male'),
  ('BARTOLOME', 'Male'),
  ('ROMER', 'Male'),
  ('RHENIEL', 'Male'),
  ('EDMON', 'Male'),
  ('MITCHEL', 'Male'),
  ('ELMO', 'Male'),
  ('MISAEL', 'Male'),
  ('CRISTAN', 'Male'),
  ('MONICO', 'Male'),
  ('DEAN', 'Male'),
  ('JONES', 'Male'),
  ('GAUDENCIO', 'Male'),
  ('JERON', 'Male'),
  ('DARIEL', 'Male'),
  ('JOHNSON', 'Male'),
  ('BENJAMEN', 'Male'),
  ('ROMIL', 'Male'),
  ('ERVIN', 'Male'),
  ('DOROTEO', 'Male'),
  ('PRIMITIVO', 'Male'),
  ('JONREY', 'Male'),
  ('WILFRED', 'Male'),
  ('RYKER', 'Male'),
  ('ELIZAR', 'Male'),
  ('ELIZALDE', 'Male'),
  ('ABELARDO', 'Male'),
  ('HERMENIO', 'Male'),
  ('ISABELO', 'Male'),
  ('JESRIEL', 'Male'),
  ('WENDEL', 'Male'),
  ('ELISEO', 'Male'),
  ('ALMAR', 'Male'),
  ('ARCADIO', 'Male'),
  ('JOEVANIE', 'Male'),
  ('KHALID', 'Male'),
  ('ANTONY', 'Male'),
  ('REYNARD', 'Male'),
  ('FRANCO', 'Male'),
  ('REYMUNDO', 'Male'),
  ('NAPOLEON', 'Male'),
  ('VIRGIL', 'Male'),
  ('ESTELITO', 'Male'),
  ('FROILAN', 'Male'),
  ('JHONRY', 'Male'),
  ('MELITON', 'Male'),
  ('REYDEN', 'Male'),
  ('VERGELIO', 'Male'),
  ('MARCIAL', 'Male'),
  ('ZAYDEN', 'Male'),
  ('ALJEN', 'Male'),
  ('VENCENT', 'Male'),
  ('ANSELMO', 'Male'),
  ('CESARIO', 'Male'),
  ('ENZO', 'Male'),
  ('MARCUS', 'Male'),
  ('SANTINO', 'Male'),
  ('ORVILLE', 'Male'),
  ('ELEAZAR', 'Male'),
  ('JETHER', 'Male'),
  ('ROSELO', 'Male'),
  ('AXL', 'Male'),
  ('NHIEL', 'Male'),
  ('FAUSTINO', 'Male'),
  ('RECARDO', 'Male'),
  ('JALIL', 'Male'),
  ('RENALD', 'Male'),
  ('SEBASTIAN', 'Male'),
  ('ROSALITO', 'Male'),
  ('TIMOTHY', 'Male'),
  ('TIMOTEO', 'Male'),
  ('ABEL', 'Male'),
  ('THIRDY', 'Male'),
  ('MAX', 'Male'),
  ('JOVANNIE', 'Male'),
  ('ESTEBAN', 'Male'),
  ('ISRAEL', 'Male'),
  ('EMERSON', 'Male'),
  ('GEOFFREY', 'Male'),
  ('AIDAN', 'Male'),
  ('JANREY', 'Male'),
  ('FELMAR', 'Male'),
  ('NEMUEL', 'Male'),
  ('KOBE', 'Male'),
  ('RENHEART', 'Male'),
  ('CIPRIANO', 'Male'),
  ('JHONY', 'Male'),
  ('EDWEN', 'Male'),
  ('RENEL', 'Male'),
  ('BERT', 'Male'),
  ('ANASTACIO', 'Male'),
  ('LIMUEL', 'Male'),
  ('ARMAND', 'Male'),
  ('ALEXA', 'Female'),
  ('ELIZABETH', 'Female'),
  ('ROSE', 'Female'),
  ('ARLYN', 'Female'),
  ('MARIEL', 'Female'),
  ('ROSALIE', 'Female'),
  ('VILMA', 'Female'),
  ('IRISH', 'Female'),
  ('HONEY', 'Female'),
  ('IRENE', 'Female'),
  ('SAMANTHA', 'Female'),
  ('LOLITA', 'Female'),
  ('ALMA', 'Female'),
  ('MARILYN', 'Female'),
  ('MAE', 'Female'),
  ('HANNAH', 'Female'),
  ('ROWENA', 'Female'),
  ('ANGELA', 'Female'),
  ('ANA', 'Female'),
  ('ERLINDA', 'Female'),
  ('LEAH', 'Female'),
  ('EMMA', 'Female'),
  ('SARAH', 'Female'),
  ('DIANA', 'Female'),
  ('LORNA', 'Female'),
  ('MARILOU', 'Female'),
  ('ANGELICA', 'Female'),
  ('MELANIE', 'Female'),
  ('ROSEMARIE', 'Female'),
  ('GLORIA', 'Female'),
  ('JESSICA', 'Female'),
  ('CATHERINE', 'Female'),
  ('SUSAN', 'Female'),
  ('JENNIFER', 'Female'),
  ('VIRGINIA', 'Female'),
  ('ROSELYN', 'Female'),
  ('JONALYN', 'Female'),
  ('ANNA', 'Female'),
  ('MARITES', 'Female'),
  ('MERCY', 'Female'),
  ('CRISTINE', 'Female'),
  ('ARLENE', 'Female'),
  ('DAISY', 'Female'),
  ('AILYN', 'Female'),
  ('LIZA', 'Female'),
  ('EVANGELINE', 'Female'),
  ('KRISTINE', 'Female'),
  ('SHIELA', 'Female'),
  ('ELLA', 'Female'),
  ('JULIETA', 'Female'),
  ('MYRNA', 'Female'),
  ('MAY', 'Female'),
  ('RUTH', 'Female'),
  ('SHEILA', 'Female'),
  ('SOFIA', 'Female'),
  ('ROSITA', 'Female'),
  ('REBECCA', 'Female'),
  ('MARIVIC', 'Female'),
  ('CHERYL', 'Female'),
  ('ELSA', 'Female'),
  ('JANETH', 'Female'),
  ('ELENA', 'Female'),
  ('LEA', 'Female'),
  ('LEONORA', 'Female'),
  ('JANE', 'Female'),
  ('REGINE', 'Female'),
  ('TRISHA', 'Female'),
  ('KATE', 'Female'),
  ('MARGIE', 'Female'),
  ('MERRY', 'Female'),
  ('JASMINE', 'Female'),
  ('NICOLE', 'Female'),
  ('AIZA', 'Female'),
  ('ROSALINDA', 'Female'),
  ('LIEZEL', 'Female'),
  ('RICA', 'Female'),
  ('ANDREA', 'Female'),
  ('JULIET', 'Female'),
  ('JUDITH', 'Female'),
  ('RIZA', 'Female'),
  ('JULIA', 'Female'),
  ('CRISTINA', 'Female'),
  ('EDNA', 'Female'),
  ('FE', 'Female'),
  ('ANALIZA', 'Female'),
  ('LOURDES', 'Female'),
  ('MARJORIE', 'Female'),
  ('VIVIAN', 'Female'),
  ('CRISTY', 'Female'),
  ('VANESSA', 'Female'),
  ('STEPHANIE', 'Female'),
  ('NORMA', 'Female'),
  ('MARIBEL', 'Female'),
  ('ELSIE', 'Female'),
  ('GERALDINE', 'Female'),
  ('NENITA', 'Female'),
  ('SHAIRA', 'Female'),
  ('DIVINE', 'Female'),
  ('KIMBERLY', 'Female'),
  ('MARLYN', 'Female'),
  ('JAMAICA', 'Female'),
  ('VICTORIA', 'Female'),
  ('EVA', 'Female'),
  ('LYDIA', 'Female'),
  ('CARMELITA', 'Female'),
  ('WILMA', 'Female'),
  ('ANGELYN', 'Female'),
  ('TRIXIE', 'Female'),
  ('MARISSA', 'Female'),
  ('ELLEN', 'Female'),
  ('KAREN', 'Female'),
  ('DELIA', 'Female'),
  ('MARIAN', 'Female'),
  ('LADY', 'Female'),
  ('LUCIA', 'Female'),
  ('DIVINA', 'Female'),
  ('MANILYN', 'Female'),
  ('MARRY', 'Female'),
  ('BEVERLY', 'Female'),
  ('RACHEL', 'Female'),
  ('ANITA', 'Female'),
  ('KEZIAH', 'Female'),
  ('ANNIE', 'Female'),
  ('ALICIA', 'Female'),
  ('EDITHA', 'Female'),
  ('NANCY', 'Female'),
  ('CORAZON', 'Female'),
  ('MARIE', 'Female'),
  ('RAQUEL', 'Female'),
  ('LILIBETH', 'Female'),
  ('JASMIN', 'Female'),
  ('JUANITA', 'Female'),
  ('LILIA', 'Female'),
  ('REA', 'Female'),
  ('KYLA', 'Female'),
  ('BEA', 'Female'),
  ('LANIE', 'Female'),
  ('APPLE', 'Female'),
  ('DANICA', 'Female'),
  ('IMELDA', 'Female'),
  ('CLAIRE', 'Female'),
  ('RIZZA', 'Female'),
  ('RUBY', 'Female'),
  ('PHOEBE', 'Female'),
  ('ELMA', 'Female'),
  ('EMILY', 'Female'),
  ('FLORA', 'Female'),
  ('PRINCES', 'Female'),
  ('QUEENIE', 'Female'),
  ('LETECIA', 'Female'),
  ('TERESA', 'Female'),
  ('CHLOE', 'Female'),
  ('ATHENA', 'Female'),
  ('VERONICA', 'Female'),
  ('MELODY', 'Female'),
  ('QUEEN', 'Female'),
  ('CHARLENE', 'Female'),
  ('MYLENE', 'Female'),
  ('ELAIZA', 'Female'),
  ('GENEVIEVE', 'Female'),
  ('ESTRELLA', 'Female'),
  ('JANET', 'Female'),
  ('ANNABELLE', 'Female'),
  ('ZIA', 'Female'),
  ('JOYCE', 'Female'),
  ('LOVELYN', 'Female'),
  ('JOANA', 'Female'),
  ('CHARLYN', 'Female'),
  ('JULIANA', 'Female'),
  ('RONA', 'Female'),
  ('RODELYN', 'Female'),
  ('AYESHA', 'Female'),
  ('SUSANA', 'Female'),
  ('THELMA', 'Female'),
  ('KATHLEEN', 'Female'),
  ('JOSIE', 'Female'),
  ('GENELYN', 'Female'),
  ('LORENA', 'Female'),
  ('FAITH', 'Female'),
  ('HANNA', 'Female'),
  ('MERLITA', 'Female'),
  ('ELVIRA', 'Female'),
  ('JUVY', 'Female'),
  ('CHRISTY', 'Female'),
  ('CECILIA', 'Female'),
  ('ANGELINE', 'Female'),
  ('MILAGROS', 'Female'),
  ('NIÑA', 'Female'),
  ('TESSIE', 'Female'),
  ('CASSANDRA', 'Female'),
  ('MERLINDA', 'Female'),
  ('ROSALINA', 'Female'),
  ('LEONILA', 'Female'),
  ('ERICA', 'Female'),
  ('ANGELITA', 'Female'),
  ('ANGELIE', 'Female'),
  ('ROXANNE', 'Female'),
  ('MARICAR', 'Female'),
  ('ELVIE', 'Female'),
  ('MIA', 'Female'),
  ('FLORDELIZA', 'Female'),
  ('CHARITY', 'Female'),
  ('MERCEDITA', 'Female'),
  ('ZENAIDA', 'Female'),
  ('CINDY', 'Female'),
  ('RENALYN', 'Female'),
  ('MERIAM', 'Female'),
  ('JENALYN', 'Female'),
  ('ALLIAH', 'Female'),
  ('JANINE', 'Female'),
  ('ELISA', 'Female'),
  ('AILEEN', 'Female'),
  ('LUZVIMINDA', 'Female'),
  ('EMELYN', 'Female'),
  ('BABY', 'Female'),
  ('JOANNA', 'Female'),
  ('CRYSTAL', 'Female'),
  ('AIRA', 'Female'),
  ('ABEGAIL', 'Female'),
  ('MERLY', 'Female'),
  ('DOLORES', 'Female'),
  ('NENA', 'Female'),
  ('SHEENA', 'Female'),
  ('MARCELINA', 'Female'),
  ('SONIA', 'Female'),
  ('SITTIE', 'Female'),
  ('MIRASOL', 'Female'),
  ('ANABEL', 'Female'),
  ('CONCEPCION', 'Female'),
  ('PATRICIA', 'Female'),
  ('NORA', 'Female'),
  ('AIDA', 'Female'),
  ('LENIE', 'Female'),
  ('JOSEFINA', 'Female'),
  ('MILA', 'Female'),
  ('SHELLA', 'Female'),
  ('ANECITA', 'Female'),
  ('CHONA', 'Female'),
  ('GRETCHEN', 'Female'),
  ('ANGELINA', 'Female'),
  ('ADELAIDA', 'Female'),
  ('ROSA', 'Female'),
  ('CARMELA', 'Female'),
  ('AMALIA', 'Female'),
  ('LUZ', 'Female'),
  ('ROSALYN', 'Female'),
  ('SHAINA', 'Female'),
  ('BERNADETH', 'Female'),
  ('SCARLET', 'Female'),
  ('ADELINA', 'Female'),
  ('EDELYN', 'Female'),
  ('VERGIE', 'Female'),
  ('EMELIA', 'Female'),
  ('JENILYN', 'Female'),
  ('WENDY', 'Female'),
  ('JANELLE', 'Female'),
  ('JULITA', 'Female'),
  ('JILLIAN', 'Female'),
  ('PERLITA', 'Female'),
  ('ESTELITA', 'Female'),
  ('NELLY', 'Female'),
  ('SHERLY', 'Female'),
  ('REGINA', 'Female'),
  ('SHERYL', 'Female'),
  ('EMELY', 'Female'),
  ('NATHALIA', 'Female'),
  ('GLAIZA', 'Female'),
  ('JINKY', 'Female'),
  ('BRIANNA', 'Female'),
  ('LYCA', 'Female'),
  ('DINA', 'Female'),
  ('CONCHITA', 'Female'),
  ('ARA', 'Female'),
  ('ESTERLITA', 'Female'),
  ('RONALYN', 'Female'),
  ('ESTELA', 'Female'),
  ('LUCITA', 'Female'),
  ('JERALYN', 'Female'),
  ('ALONA', 'Female'),
  ('NIDA', 'Female'),
  ('NELIA', 'Female'),
  ('REMEDIOS', 'Female'),
  ('KYLIE', 'Female'),
  ('JENEFER', 'Female'),
  ('ALIYAH', 'Female'),
  ('ROSANA', 'Female'),
  ('ANALIE', 'Female'),
  ('MARIFE', 'Female'),
  ('JANNA', 'Female'),
  ('CATALINA', 'Female'),
  ('AGNES', 'Female'),
  ('BEATRIZ', 'Female'),
  ('NILDA', 'Female'),
  ('SHARON', 'Female'),
  ('EMELITA', 'Female'),
  ('MARGARITA', 'Female'),
  ('AMARAH', 'Female'),
  ('FATIMA', 'Female'),
  ('JELYN', 'Female'),
  ('ESTHER', 'Female'),
  ('GLENDA', 'Female'),
  ('DANIELLA', 'Female'),
  ('RICHELLE', 'Female'),
  ('RENA', 'Female'),
  ('RECHEL', 'Female'),
  ('DANIELA', 'Female'),
  ('JENIFER', 'Female'),
  ('LINDA', 'Female'),
  ('MECHELLE', 'Female'),
  ('DONNA', 'Female'),
  ('KRISHA', 'Female'),
  ('JANELLA', 'Female'),
  ('SHIRLEY', 'Female'),
  ('ANNALIZA', 'Female'),
  ('JANICA', 'Female'),
  ('ALEAH', 'Female'),
  ('GWEN', 'Female'),
  ('JOHANNA', 'Female'),
  ('ROVELYN', 'Female'),
  ('JOANN', 'Female'),
  ('LAIZA', 'Female'),
  ('FELY', 'Female'),
  ('KEISHA', 'Female'),
  ('LINA', 'Female'),
  ('MADELYN', 'Female'),
  ('LORETA', 'Female'),
  ('GLADYS', 'Female'),
  ('MILDRED', 'Female'),
  ('FRANCES', 'Female'),
  ('ANABELLE', 'Female'),
  ('LEIZEL', 'Female'),
  ('PEARL', 'Female'),
  ('REALYN', 'Female'),
  ('JERLYN', 'Female'),
  ('ANNALYN', 'Female'),
  ('NATHALIE', 'Female'),
  ('MICA', 'Female'),
  ('MONICA', 'Female'),
  ('PACITA', 'Female'),
  ('RECHELLE', 'Female'),
  ('ROGELYN', 'Female'),
  ('BRENDA', 'Female'),
  ('NATIVIDAD', 'Female'),
  ('MELINDA', 'Female'),
  ('MELISSA', 'Female'),
  ('MARIANNE', 'Female'),
  ('ZYRA', 'Female'),
  ('ZOE', 'Female'),
  ('RAIZA', 'Female'),
  ('ROSIE', 'Female'),
  ('SALLY', 'Female'),
  ('VIRGIE', 'Female'),
  ('BLESSY', 'Female'),
  ('FRANCISCA', 'Female'),
  ('EUNICE', 'Female'),
  ('LEONIDA', 'Female'),
  ('JUVELYN', 'Female'),
  ('CLARITA', 'Female'),
  ('JACKELYN', 'Female'),
  ('AMARA', 'Female'),
  ('VENUS', 'Female'),
  ('RACHELLE', 'Female'),
  ('ADELA', 'Female'),
  ('LUCY', 'Female'),
  ('MELIZA', 'Female'),
  ('RUBELYN', 'Female'),
  ('MARISA', 'Female'),
  ('MAILYN', 'Female'),
  ('BETTY', 'Female'),
  ('OFELIA', 'Female'),
  ('ANALOU', 'Female'),
  ('JUNALYN', 'Female'),
  ('ARIANE', 'Female'),
  ('ABIGAIL', 'Female'),
  ('FLORENCE', 'Female'),
  ('JOLINA', 'Female'),
  ('RHEANA', 'Female'),
  ('FLORENCIA', 'Female'),
  ('AMELITA', 'Female'),
  ('TITA', 'Female'),
  ('REYNA', 'Female'),
  ('SALVACION', 'Female'),
  ('KRISTEL', 'Female'),
  ('LYKA', 'Female'),
  ('JOVITA', 'Female'),
  ('ELENITA', 'Female'),
  ('SUNSHINE', 'Female'),
  ('CRESENCIA', 'Female'),
  ('GWYNETH', 'Female'),
  ('ANNABEL', 'Female'),
  ('MARIANE', 'Female'),
  ('AMELIA', 'Female'),
  ('NIMFA', 'Female'),
  ('CHERRYL', 'Female'),
  ('LIEZL', 'Female'),
  ('BELEN', 'Female'),
  ('MICHAELA', 'Female'),
  ('DARLYN', 'Female'),
  ('ALYSSA', 'Female'),
  ('ISABEL', 'Female'),
  ('CARLA', 'Female'),
  ('PAMELA', 'Female'),
  ('ROCELYN', 'Female'),
  ('JESUSA', 'Female'),
  ('SANDRA', 'Female'),
  ('MARINA', 'Female'),
  ('JENNEFER', 'Female'),
  ('JAY-ANN', 'Female'),
  ('LUZMINDA', 'Female'),
  ('PAULINE', 'Female'),
  ('ERNA', 'Female'),
  ('AISHA', 'Female'),
  ('ALEXANDRA', 'Female'),
  ('JANNAH', 'Female'),
  ('MARCELA', 'Female'),
  ('MARIVEL', 'Female'),
  ('CHRISTINA', 'Female'),
  ('MELONA', 'Female'),
  ('SOPHIE', 'Female'),
  ('CATHY', 'Female'),
  ('GENALYN', 'Female'),
  ('ARIANA', 'Female'),
  ('FELISA', 'Female'),
  ('ANN', 'Female'),
  ('JUANA', 'Female'),
  ('MARIBETH', 'Female'),
  ('CARMEN', 'Female'),
  ('ESTER', 'Female'),
  ('LARA', 'Female'),
  ('LAILA', 'Female'),
  ('YOLANDA', 'Female'),
  ('SABRINA', 'Female'),
  ('NIKKI', 'Female'),
  ('CYNTHIA', 'Female'),
  ('SHERLYN', 'Female'),
  ('CHRISTEL', 'Female'),
  ('STELLA', 'Female'),
  ('ETHEL', 'Female'),
  ('MAGDALENA', 'Female'),
  ('OLIVIA', 'Female'),
  ('RUTCHEL', 'Female'),
  ('BELLA', 'Female'),
  ('KISHA', 'Female'),
  ('MELBA', 'Female'),
  ('ERIKA', 'Female'),
  ('MARICRIS', 'Female'),
  ('YVONNE', 'Female'),
  ('MERCEDES', 'Female'),
  ('CECILLE', 'Female'),
  ('RITA', 'Female'),
  ('RUFFA', 'Female'),
  ('ANTONIETA', 'Female'),
  ('MARY-ANN', 'Female'),
  ('DIANE', 'Female'),
  ('RIA', 'Female'),
  ('MARYJANE', 'Female'),
  ('KATHLYN', 'Female'),
  ('CHELSEA', 'Female'),
  ('GERLIE', 'Female'),
  ('RHEALYN', 'Female'),
  ('JERALDINE', 'Female'),
  ('KATHERINE', 'Female'),
  ('JEZZA', 'Female'),
  ('AIZEL', 'Female'),
  ('GRACELYN', 'Female'),
  ('NELFA', 'Female'),
  ('ABBY', 'Female'),
  ('REMELYN', 'Female'),
  ('CRISTAL', 'Female'),
  ('FIONA', 'Female'),
  ('SHEKINAH', 'Female'),
  ('SHERLITA', 'Female'),
  ('RHIANNA', 'Female'),
  ('MYRA', 'Female'),
  ('ALMERA', 'Female'),
  ('ROSALITA', 'Female'),
  ('DARLENE', 'Female'),
  ('BERNADETTE', 'Female'),
  ('ALEJANDRA', 'Female'),
  ('SHANTAL', 'Female'),
  ('JENNIE', 'Female'),
  ('EUFEMIA', 'Female'),
  ('ELLIANA', 'Female'),
  ('KIESHA', 'Female'),
  ('AISA', 'Female'),
  ('MIRAFLOR', 'Female'),
  ('KAYE', 'Female'),
  ('DIANNE', 'Female'),
  ('MEA', 'Female'),
  ('TREXIE', 'Female'),
  ('BRIANA', 'Female'),
  ('LETICIA', 'Female'),
  ('JAZZY', 'Female'),
  ('THALIA', 'Female'),
  ('TEODORA', 'Female'),
  ('ZOEY', 'Female'),
  ('QUENNIE', 'Female'),
  ('DINAH', 'Female'),
  ('JOYLYN', 'Female'),
  ('DESIREE', 'Female'),
  ('CHESKA', 'Female'),
  ('MAXINE', 'Female'),
  ('AILENE', 'Female'),
  ('GIANNA', 'Female'),
  ('PILAR', 'Female'),
  ('LORAINE', 'Female'),
  ('KAYLEE', 'Female'),
  ('SHANIA', 'Female'),
  ('MERCIDITA', 'Female'),
  ('EPIFANIA', 'Female'),
  ('HILDA', 'Female'),
  ('PAULA', 'Female'),
  ('ERLYN', 'Female'),
  ('RUFINA', 'Female'),
  ('VICKY', 'Female'),
  ('SHIRLY', 'Female'),
  ('LUCRESIA', 'Female'),
  ('AUDREY', 'Female'),
  ('IRIS', 'Female'),
  ('BLESSIE', 'Female'),
  ('NERISSA', 'Female'),
  ('PRISCILLA', 'Female'),
  ('ARSENIA', 'Female'),
  ('VIA', 'Female'),
  ('LEONARDA', 'Female'),
  ('MARIETTA', 'Female'),
  ('AKIESHA', 'Female'),
  ('AMY', 'Female'),
  ('LOUISE', 'Female'),
  ('CECELIA', 'Female'),
  ('GINALYN', 'Female'),
  ('DEVINE', 'Female'),
  ('ROCHELLE', 'Female'),
  ('CHARISH', 'Female'),
  ('AUBREY', 'Female'),
  ('HERMINIA', 'Female'),
  ('GIRLIE', 'Female'),
  ('BELINDA', 'Female'),
  ('JELAICA', 'Female'),
  ('FLORAMIE', 'Female'),
  ('JENNELYN', 'Female'),
  ('AALIYAH', 'Female'),
  ('AIRENE', 'Female'),
  ('BIANCA', 'Female'),
  ('ERICKA', 'Female'),
  ('JOSEFA', 'Female'),
  ('LIGAYA', 'Female'),
  ('CANDELARIA', 'Female'),
  ('LUISA', 'Female'),
  ('ZYRAH', 'Female'),
  ('WENNIE', 'Female'),
  ('ALLEAH', 'Female'),
  ('ANGIE', 'Female'),
  ('AMIE', 'Female'),
  ('JHANNA', 'Female'),
  ('ROSABELLA', 'Female'),
  ('CLAUDINE', 'Female'),
  ('SHIELLA', 'Female'),
  ('PIA', 'Female'),
  ('ROSALIA', 'Female'),
  ('THEA', 'Female'),
  ('KIARA', 'Female'),
  ('EMERITA', 'Female'),
  ('JUDITHA', 'Female'),
  ('KIANA', 'Female'),
  ('RENELYN', 'Female'),
  ('LILIAN', 'Female'),
  ('KEZIA', 'Female'),
  ('TRIXY', 'Female'),
  ('HEZEL', 'Female'),
  ('ALAIZA', 'Female'),
  ('EMELDA', 'Female'),
  ('ANASTACIA', 'Female'),
  ('SHENNA', 'Female'),
  ('MARIALYN', 'Female'),
  ('CLARA', 'Female'),
  ('DIANNA', 'Female'),
  ('ANALISA', 'Female'),
  ('GERALYN', 'Female'),
  ('KATRINA', 'Female'),
  ('JANA', 'Female'),
  ('MELODIA', 'Female'),
  ('ADELFA', 'Female'),
  ('DAPHNE', 'Female'),
  ('PRENCESS', 'Female'),
  ('SHYRA', 'Female'),
  ('MERILYN', 'Female'),
  ('MERLINA', 'Female'),
  ('FLORIDA', 'Female'),
  ('ESTELLA', 'Female'),
  ('RHONA', 'Female'),
  ('CHARMINE', 'Female'),
  ('CHERILYN', 'Female'),
  ('AVIANNA', 'Female'),
  ('HERLYN', 'Female'),
  ('XYRAH', 'Female'),
  ('ANTONETTE', 'Female'),
  ('AIRAH', 'Female'),
  ('LUCENA', 'Female'),
  ('JONNA', 'Female'),
  ('ANDRESA', 'Female'),
  ('CRISTITA', 'Female'),
  ('CRISHA', 'Female'),
  ('CHARICE', 'Female'),
  ('GERTRUDES', 'Female'),
  ('YNA', 'Female'),
  ('LAILANIE', 'Female'),
  ('MARYJOY', 'Female'),
  ('LENY', 'Female'),
  ('NICA', 'Female'),
  ('JUDELYN', 'Female'),
  ('RINA', 'Female'),
  ('CHARMAINE', 'Female'),
  ('JENY', 'Female'),
  ('JANELYN', 'Female'),
  ('LISA', 'Female'),
  ('CELESTINE', 'Female'),
  ('IVIE', 'Female'),
  ('NOEME', 'Female'),
  ('NOEMI', 'Female'),
  ('ERMA', 'Female'),
  ('LIANA', 'Female'),
  ('ALBERTA', 'Female'),
  ('FEBIE', 'Female'),
  ('ALMIRA', 'Female'),
  ('BRITNEY', 'Female'),
  ('JIANNA', 'Female'),
  ('THERESA', 'Female'),
  ('PINKY', 'Female'),
  ('PAULINA', 'Female'),
  ('IRAH', 'Female'),
  ('RETCHEL', 'Female'),
  ('AINAH', 'Female'),
  ('PERLA', 'Female'),
  ('ATARAH', 'Female'),
  ('KATHY', 'Female'),
  ('LYZA', 'Female'),
  ('ATHALIA', 'Female'),
  ('ATHEA', 'Female'),
  ('LYRA', 'Female'),
  ('JOANNE', 'Female'),
  ('KRYSTEL', 'Female'),
  ('PRECILLA', 'Female'),
  ('MELISA', 'Female'),
  ('NORBERTA', 'Female'),
  ('GENA', 'Female'),
  ('SAIRA', 'Female'),
  ('VIVENCIA', 'Female'),
  ('ARABELLA', 'Female'),
  ('CREZEL', 'Female'),
  ('ADELYN', 'Female'),
  ('CAMILLE', 'Female'),
  ('WENDELYN', 'Female'),
  ('ISABELLA', 'Female'),
  ('REZEL', 'Female'),
  ('CRISEL', 'Female'),
  ('MARIELLE', 'Female'),
  ('WINNIE', 'Female'),
  ('LAICA', 'Female'),
  ('ELLAH', 'Female'),
  ('ALTHIA', 'Female'),
  ('CARIDAD', 'Female'),
  ('RHEANNA', 'Female'),
  ('LALAINE', 'Female'),
  ('ARCELI', 'Female'),
  ('MINDA', 'Female'),
  ('JONA', 'Female'),
  ('ELNA', 'Female'),
  ('MONA', 'Female'),
  ('MONALIZA', 'Female'),
  ('RHIANA', 'Female'),
  ('MYCA', 'Female'),
  ('MYLA', 'Female'),
  ('LORRAINE', 'Female'),
  ('GIA', 'Female'),
  ('ELVERA', 'Female'),
  ('CAROL', 'Female'),
  ('CAROLINA', 'Female'),
  ('NAOMI', 'Female'),
  ('NARCISA', 'Female'),
  ('ISIDRA', 'Female'),
  ('NATALIA', 'Female'),
  ('KENDRA', 'Female'),
  ('DOMINGA', 'Female'),
  ('ROSELA', 'Female'),
  ('CELESTE', 'Female'),
  ('AIREN', 'Female'),
  ('QUENIE', 'Female'),
  ('ANTONIA', 'Female'),
  ('RIEZEL', 'Female'),
  ('GENEROSE', 'Female'),
  ('GILDA', 'Female'),
  ('CONSOLACION', 'Female'),
  ('SAVANNAH', 'Female'),
  ('KRISTINA', 'Female'),
  ('NAOME', 'Female'),
  ('JACQUELINE', 'Female'),
  ('MERALYN', 'Female'),
  ('LITA', 'Female'),
  ('GENEVIE', 'Female'),
  ('KRISTELLE', 'Female'),
  ('AVELINA', 'Female'),
  ('RHEANNE', 'Female'),
  ('RHODORA', 'Female'),
  ('JAMELA', 'Female'),
  ('CRISANTA', 'Female'),
  ('MAYLENE', 'Female'),
  ('HYACINTH', 'Female'),
  ('ALECIA', 'Female'),
  ('NELDA', 'Female'),
  ('SALOME', 'Female'),
  ('KIANNA', 'Female'),
  ('NOREEN', 'Female'),
  ('KRISHIA', 'Female'),
  ('ALIAH', 'Female'),
  ('VICENTA', 'Female'),
  ('MARIETA', 'Female'),
  ('MADILYN', 'Female'),
  ('BONIFACIA', 'Female'),
  ('JODELYN', 'Female'),
  ('SOLEDAD', 'Female'),
  ('JAMAICAH', 'Female'),
  ('CHARITA', 'Female'),
  ('QUEENY', 'Female'),
  ('FELOMINA', 'Female'),
  ('PRECY', 'Female'),
  ('TEOFILA', 'Female'),
  ('VEVENCIA', 'Female'),
  ('SHENA', 'Female'),
  ('MATILDE', 'Female'),
  ('DANNA', 'Female'),
  ('NATALIE', 'Female'),
  ('JEANIE', 'Female'),
  ('SHELA', 'Female'),
  ('ANICA', 'Female'),
  ('LEONCIA', 'Female'),
  ('JAZEL', 'Female'),
  ('FEBBIE', 'Female'),
  ('MYLEN', 'Female'),
  ('CRISLYN', 'Female'),
  ('LOIDA', 'Female'),
  ('MAGDALINA', 'Female'),
  ('ALLYSA', 'Female'),
  ('VERGINIA', 'Female'),
  ('SHARMAINE', 'Female'),
  ('FELIZA', 'Female'),
  ('MAICA', 'Female'),
  ('JEANETTE', 'Female'),
  ('LORELYN', 'Female'),
  ('CHARYL', 'Female'),
  ('CERILA', 'Female'),
  ('ESPERANZA', 'Female'),
  ('GELYN', 'Female'),
  ('FREYA', 'Female'),
  ('ANGELIKA', 'Female'),
  ('DIONESIA', 'Female'),
  ('JESSABEL', 'Female'),
  ('CZARINA', 'Female'),
  ('MIGUELA', 'Female'),
  ('MARICHU', 'Female'),
  ('CASSY', 'Female'),
  ('LUCILA', 'Female'),
  ('JENEVIEVE', 'Female'),
  ('MELCHORA', 'Female'),
  ('JESSAMAE', 'Female'),
  ('CELIA', 'Female'),
  ('ZAHARA', 'Female'),
  ('ISABELITA', 'Female'),
  ('APOLINARIA', 'Female'),
  ('ROBELYN', 'Female'),
  ('ROMELYN', 'Female'),
  ('RACHELL', 'Female'),
  ('BARBIE', 'Female'),
  ('CHARIE', 'Female'),
  ('CAMELA', 'Female'),
  ('ARIELLA', 'Female'),
  ('ROSELLE', 'Female'),
  ('JONAMAE', 'Female'),
  ('PRESCIOUS', 'Female'),
  ('VALERIANA', 'Female'),
  ('AVA', 'Female'),
  ('MISSY', 'Female'),
  ('SARA', 'Female'),
  ('ELLIE', 'Female'),
  ('LEONITA', 'Female'),
  ('GIRLY', 'Female'),
  ('URSULA', 'Female'),
  ('CHARINA', 'Female'),
  ('RIHANNA', 'Female'),
  ('REYNALYN', 'Female'),
  ('CLEOFE', 'Female'),
  ('RUBILYN', 'Female'),
  ('MONIQUE', 'Female'),
  ('ZOSIMA', 'Female'),
  ('HAILEY', 'Female'),
  ('KISSHA', 'Female'),
  ('MIRALUNA', 'Female'),
  ('JHOANNA', 'Female'),
  ('MIRA', 'Female'),
  ('MARIAFE', 'Female'),
  ('FELICIANA', 'Female'),
  ('IMEE', 'Female'),
  ('KESHIA', 'Female'),
  ('JENEROSE', 'Female'),
  ('CLARISSA', 'Female'),
  ('JULIANNE', 'Female'),
  ('RIZALINA', 'Female'),
  ('NIEVES', 'Female'),
  ('LANI', 'Female'),
  ('CHERLY', 'Female'),
  ('NOVELYN', 'Female'),
  ('XYRELLE', 'Female'),
  ('ENGRACIA', 'Female'),
  ('MINERVA', 'Female'),
  ('MANELYN', 'Female'),
  ('CHERIE', 'Female'),
  ('CHERELYN', 'Female'),
  ('LOVELLA', 'Female'),
  ('CARINA', 'Female'),
  ('JESA', 'Female'),
  ('FLORENDA', 'Female'),
  ('JESABEL', 'Female'),
  ('JANESSA', 'Female'),
  ('MIKYLA', 'Female'),
  ('YSABELLA', 'Female'),
  ('CHARISSE', 'Female'),
  ('EDNALYN', 'Female'),
  ('FRITZIE', 'Female'),
  ('CRISELDA', 'Female'),
  ('EUGENIA', 'Female'),
  ('LUCIANA', 'Female'),
  ('BEVERLYN', 'Female'),
  ('ROWELYN', 'Female'),
  ('LUCILLE', 'Female'),
  ('ROWELA', 'Female'),
  ('JULLIA', 'Female'),
  ('CHRISTAL', 'Female'),
  ('JORALYN', 'Female'),
  ('ANNALOU', 'Female'),
  ('KEMBERLY', 'Female'),
  ('EDLYN', 'Female'),
  ('AURELIA', 'Female'),
  ('LEONA', 'Female'),
  ('WARLITA', 'Female'),
  ('CAROLINE', 'Female'),
  ('CELSA', 'Female'),
  ('KYLENE', 'Female'),
  ('MERASOL', 'Female'),
  ('MERALONA', 'Female'),
  ('HAIDEE', 'Female'),
  ('JHONA', 'Female'),
  ('VINA', 'Female'),
  ('JEANILYN', 'Female'),
  ('JHONALYN', 'Female'),
  ('EMALYN', 'Female'),
  ('ELEONOR', 'Female'),
  ('MARIANITA', 'Female'),
  ('AIMEE', 'Female'),
  ('NICHOLE', 'Female'),
  ('CHERRYLYN', 'Female'),
  ('JANAH', 'Female'),
  ('VENICE', 'Female'),
  ('JOANNAH', 'Female'),
  ('ROSEMARY', 'Female'),
  ('MARIZA', 'Female'),
  ('JERELYN', 'Female'),
  ('ATHALIAH', 'Female'),
  ('JOANAH', 'Female'),
  ('ADORA', 'Female'),
  ('MEKAILA', 'Female'),
  ('KATHRYN', 'Female'),
  ('GRETCHEL', 'Female'),
  ('MEGAN', 'Female'),
  ('AYEISHA', 'Female'),
  ('ESMERALDA', 'Female'),
  ('SCARLETT', 'Female'),
  ('TRESHA', 'Female'),
  ('ROSANNA', 'Female'),
  ('PAULEEN', 'Female'),
  ('TIFFANY', 'Female'),
  ('AMANDA', 'Female'),
  ('ALLIYAH', 'Female'),
  ('AMIRA', 'Female'),
  ('ANELYN', 'Female'),
  ('KATELYN', 'Female'),
  ('MAUREEN', 'Female'),
  ('JAZLYN', 'Female'),
  ('DELMA', 'Female'),
  ('JEZELLE', 'Female'),
  ('ASHIANNA', 'Female'),
  ('ALLYZA', 'Female'),
  ('MARELYN', 'Female'),
  ('MARYCRIS', 'Female'),
  ('EMILIA', 'Female'),
  ('BRIELLE', 'Female'),
  ('KHATE', 'Female'),
  ('JEMALYN', 'Female'),
  ('FELIPA', 'Female'),
  ('CLAUDIA', 'Female'),
  ('LIBRADA', 'Female'),
  ('CECILE', 'Female'),
  ('AMINAH', 'Female'),
  ('LIA', 'Female'),
  ('RODA', 'Female'),
  ('JENEVIE', 'Female')
on conflict (name) do update set gender = excluded.gender;

update family_members fm
set gender = g.gender, updated_date = now()
from first_name_gender g
where fm.gender is null
  and g.gender is not null
  and g.name = upper(trim(split_part(trim(fm.firstname), ' ', 1)));

-- Check the result:
--   select gender, count(*) from family_members group by 1;
--
-- Next batch of names not yet classified (export, add to the CSV, re-run this file):
--   select upper(trim(split_part(trim(firstname), ' ', 1))) as name, count(*) as n
--   from family_members
--   where gender is null and coalesce(trim(firstname), '') <> ''
--     and upper(trim(split_part(trim(firstname), ' ', 1))) not in (select name from first_name_gender)
--   group by 1 order by n desc;
--
-- Members left for manual review (unisex names):
--   select id, lastname, firstname, barangay from family_members
--   where gender is null order by barangay, lastname;
