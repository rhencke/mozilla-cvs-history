<?php
/* SVN FILE: $Id: folder.test.php,v 1.2 2007-11-19 08:49:56 rflint%ryanflint.com Exp $ */
/**
 * Short description for file.
 *
 * Long description for file
 *
 * PHP versions 4 and 5
 *
 * CakePHP(tm) Tests <https://trac.cakephp.org/wiki/Developement/TestSuite>
 * Copyright 2005-2007, Cake Software Foundation, Inc.
 *								1785 E. Sahara Avenue, Suite 490-204
 *								Las Vegas, Nevada 89104
 *
 *  Licensed under The Open Group Test Suite License
 *  Redistributions of files must retain the above copyright notice.
 *
 * @filesource
 * @copyright		Copyright 2005-2007, Cake Software Foundation, Inc.
 * @link				https://trac.cakephp.org/wiki/Developement/TestSuite CakePHP(tm) Tests
 * @package			cake.tests
 * @subpackage		cake.tests.cases.libs
 * @since			CakePHP(tm) v 1.2.0.4206
 * @version			$Revision: 1.2 $
 * @modifiedby		$LastChangedBy: phpnut $
 * @lastmodified	$Date: 2007-11-19 08:49:56 $
 * @license			http://www.opensource.org/licenses/opengroup.php The Open Group Test Suite License
 */
uses('folder');
/**
 * Short description for class.
 *
 * @package		cake.tests
 * @subpackage	cake.tests.cases.libs
 */
class FolderTest extends UnitTestCase {

	var $Folder = null;

	function testBasic() {
		$path = dirname(__FILE__);
		$Folder =& new Folder($path);

		$result = $Folder->pwd();
		$this->assertEqual($result, $path);

		$result = $Folder->addPathElement($path, 'test');
		$expected = $path . DS . 'test';
		$this->assertEqual($result, $expected);

		$result = $Folder->cd(ROOT);
		$expected = ROOT;
		$this->assertEqual($result, $expected);
	}

	function testInPath() {
		$path = dirname(dirname(__FILE__));
		$inside = dirname($path) . DS;

		$Folder =& new Folder($path);

		$result = $Folder->pwd();
		$this->assertEqual($result, $path);

		$result = $Folder->isSlashTerm($inside);
		$this->assertTrue($result);

		$result = $Folder->realpath('tests/');
		$this->assertEqual($result, $path . DS .'tests/');

		$result = $Folder->inPath('tests/');
		$this->assertTrue($result);

		$result = $Folder->inPath(DS . 'non-existing' . $inside);
		$this->assertFalse($result);
	}

	function testOperations() {
		$path = CAKE_CORE_INCLUDE_PATH.DS.'cake'.DS.'console'.DS.'libs'.DS.'templates'.DS.'skel';
		$Folder =& new Folder($path);

		$result = is_dir($Folder->pwd());
		$this->assertTrue($result);

		$new = TMP . 'test_folder_new';
		$result = $Folder->create($new);
		$this->assertTrue($result);

		$copy = TMP . 'test_folder_copy';
		$result = $Folder->copy($copy);
		$this->assertTrue($result);

		$copy = TMP . 'test_folder_copy';
		$result = $Folder->chmod($copy, 0755, false);
		$this->assertTrue($result);

		$result = $Folder->cd($copy);
		$this->assertTrue($result);

		$mv = TMP . 'test_folder_mv';
		$result = $Folder->move($mv);
		$this->assertTrue($result);

		$result = $Folder->delete($new);
		$this->assertTrue($result);

		$result = $Folder->delete($mv);
		$this->assertTrue($result);
	}

	function testRealPathForWebroot() {
		$Folder = new Folder('files/');
		$this->assertEqual(realpath('files/'), $Folder->path);
	}

	function testZeroAsDirectory() {
		$Folder =& new Folder(TMP);
		$new = TMP . '0';
		$result = $Folder->create($new);
		$this->assertTrue($result);

		$result = $Folder->read(true, true);
		$expected = array(array('0', 'cache', 'logs', 'sessions', 'tests'), array());
		$this->assertEqual($expected, $result);

		$result = $Folder->read(true, array('.', '..', 'logs', '.svn'));
		$expected = array(array('0', 'cache', 'sessions', 'tests'), array());
		$this->assertEqual($expected, $result);

		$result = $Folder->delete($new);
		$this->assertTrue($result);
	}

	function testFolderRead() {
		$Folder =& new Folder(TMP);
		$expected = array('cache', 'logs', 'sessions', 'tests');
		$results = $Folder->read(true, true);
		$this->assertEqual($results[0], $expected);
	}

	function testFolderTree() {
		$Folder =& new Folder();
		$expected = array(array(CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding'),
								array(CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'config.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'paths.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0000_007f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0080_00ff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0100_017f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0180_024F.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0300_036f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0370_03ff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0400_04ff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0500_052f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '0530_058f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '10400_1044f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '10a0_10ff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '1e00_1eff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '1f00_1fff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '2100_214f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '2150_218f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '2460_24ff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '2c00_2c5f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '2c60_2c7f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . '2c80_2cff.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . 'fb00_fb4f.php',
										CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config' . DS . 'unicode' .  DS . 'casefolding' . DS . 'ff00_ffef.php'));

		$results = $Folder->tree(CAKE_CORE_INCLUDE_PATH . DS . 'cake' . DS . 'config', false);
		$this->assertEqual($results, $expected);
	}

	function testWindowsPath(){
		$Folder =& new Folder();
		$this->assertTrue($Folder->isWindowsPath('C:\cake'));
		$this->assertTrue($Folder->isWindowsPath('c:\cake'));
	}

	function testIsAbsolute(){
		$Folder =& new Folder();
		$this->assertTrue($Folder->isAbsolute('C:\cake'));
		$this->assertTrue($Folder->isAbsolute('/usr/local'));
		$this->assertFalse($Folder->isAbsolute('cake/'));
	}

	function testIsSlashTerm(){
		$Folder =& new Folder();
		$this->assertTrue($Folder->isSlashTerm('C:\cake\\'));
		$this->assertTrue($Folder->isSlashTerm('/usr/local/'));
		$this->assertFalse($Folder->isSlashTerm('cake'));
	}
}
?>