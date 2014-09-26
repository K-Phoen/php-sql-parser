<?php

namespace KPhoen\SqlParser\Tests;

use DirectoryIterator;

class SyntaxTest extends \PHPUnit_Framework_TestCase
{
    const GRAMMAR_FILE = 'sql_light.pp';
    const FIXTURES_DIR = './tests/fixtures';

    static private $compiler;

    /**
     * @beforeClass
     */
    public static function createCompiler()
    {
        self::$compiler = \Hoa\Compiler\Llk\Llk::load(new \Hoa\File\Read(self::GRAMMAR_FILE));
    }

    /**
     * @dataProvider validInputProvider
     */
    public function testParseValidInput($root_rule, $input)
    {
        $this->assertTrue(self::$compiler->parse($input, $root_rule, false));
    }

    public function validInputProvider()
    {
        $inputs = array();

        foreach (new DirectoryIterator(self::FIXTURES_DIR) as $file) {
            if ($file->isDot()) {
                continue;
            }

            // description, rule, extension
            $name_parts = explode('.', $file->getFilename());

            $inputs[] = array($name_parts[1], file_get_contents($file->getRealPath()));
        }

        return $inputs;
    }
}
