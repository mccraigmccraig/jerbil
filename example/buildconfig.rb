
SOURCE_DIR          = "src"
TEST_SOURCE_DIR     = "testsrc"
BUILD_DIR           = "build"
DIST_DIR            = "dist"
DISTJAR             = File.join(DIST_DIR, "sample_in_a.jar")
JAVA_BUILD_DIR      = "#{BUILD_DIR}"
JAVADOC_DIR         = "#{DIST_DIR}/javadoc"
TESTOUTPUTDIR       = "test-output"
JAVA_FILES          = Jerbil::JavaFileList.new(SOURCE_DIR,      JAVA_BUILD_DIR)
JAVA_TEST_FILES     = Jerbil::JavaFileList.new(TEST_SOURCE_DIR, JAVA_BUILD_DIR) 
ANNOTATED_CLASSES   = File.join(BUILD_DIR, "annotated-classes.yml")

CLASSPATH           = FileList["./#{JAVA_BUILD_DIR}", "./lib/*.jar" ]
DB_SCHEMA           = File.join(BUILD_DIR, "schema.sql")
PERSISTENCE_YML     = File.join(BUILD_DIR, "persistence.yml")
