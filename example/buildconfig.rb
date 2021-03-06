
SOURCE_DIR          = "src"
TEST_SOURCE_DIR     = "testsrc"
BUILD_DIR           = "build"
DIST_DIR            = "dist"
RESOURCES_DIR       = "resources"
DISTJAR             = File.join(DIST_DIR, "sample_in_a.jar")
JAVA_BUILD_DIR      = "#{BUILD_DIR}"
JAVADOC_DIR         = "#{DIST_DIR}/javadoc"
TESTOUTPUTDIR       = "test-output"
JAVA_FILES          = JavaFileList.new(SOURCE_DIR,      JAVA_BUILD_DIR)
JAVA_TEST_FILES     = JavaFileList.new(TEST_SOURCE_DIR, JAVA_BUILD_DIR)
JAVA_FILES_WITH_RESOURCES = JavaFileList.new(SOURCE_DIR,      JAVA_BUILD_DIR, RESOURCES_DIR)
ANNOTATED_CLASSES   = File.join(BUILD_DIR, "annotated-classes.yml")

CLASSPATH           = FileList["./#{JAVA_BUILD_DIR}", "./lib/*.jar" ]
DB_SCHEMA           = File.join(BUILD_DIR, "schema.sql")
ENTITIES_YML	      = File.join(BUILD_DIR, "entities.yml")
