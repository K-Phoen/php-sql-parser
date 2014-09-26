<?php

require_once 'vendor/autoload.php';

// 1. Load grammar.
$start = microtime(true);
$compiler = Hoa\Compiler\Llk\Llk::load(new Hoa\File\Read('sql_light.pp'));

echo sprintf('Grammar: %.6f', microtime(true) - $start) . PHP_EOL;

// 2. Parse a data.
$ast = $compiler->parse("DELETE FROM person WHERE age < 10", 'DeleteQuery');

echo sprintf('ast: %.6f', microtime(true) - $start) . PHP_EOL;

// // 3. Dump the AST.
$dump = new Hoa\Compiler\Visitor\Dump();
echo $dump->visit($ast);
