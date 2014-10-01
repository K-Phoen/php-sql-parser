%skip   space           \s

// strings
%token quote_          '        -> string
%token string:string   [^']+
%token string:_quote   '        -> default

// keywords
%token delete       DELETE
%token update       UPDATE
%token set          SET
%token select       SELECT
%token from         FROM
%token asc          ASC
%token desc         DESC
%token as           AS
%token distinct     DISTINCT
%token between      BETWEEN
%token null         NULL
%token in           IN
%token where        WHERE
%token order        ORDER
%token like         LIKE
%token by           BY
%token or           OR
%token and          AND
%token is           IS
%token not          NOT
%token case         CASE
%token when         WHEN
%token else         ELSE
%token then         THEN
%token end          END
%token group        GROUP
%token by           BY
%token having       HAVING

%token all          ALL
%token any          ANY
%token some         SOME

%token true         TRUE
%token false        FALSE

%token join         JOIN
%token inner        INNER
%token outer        OUTER
%token left         LEFT
%token right        RIGHT
%token full         FULL
%token on           ON

// aggregate functions
%token avg          AVG
%token max          MAX
%token min          MIN
%token sum          SUM
%token count        COUNT

// operators
%token op_eq        =
%token op_neq       <>
%token op_lt        <
%token op_gt        >
%token op_lte       <=
%token op_gte       >=

%token op_plus      \+
%token op_minus     \-
%token op_mul       \*
%token op_div       /

// rest
%token left_paren   \(
%token right_paren  \)
%token period       \.
%token comma        ,
%token number       \d+

// identifier
%token identifier   [a-zA-Z][a-zA-Z0-9_]*

#string:
    ::quote_:: <string> ::_quote:: | ::quote_:: ::_quote::

#number:
    <number>

#boolean:
    <true> | <false>

Literal:
    string() | number() | boolean()

#Identifier:
    <identifier>

#DatabaseIdentifier:
    Identifier()

#TablePrimaryIdentifier:
        Identifier() (::as:: Identifier())?
    |   DatabaseIdentifier() ::period:: Identifier() (::as:: Identifier())?

#OuterJoinType:
    <left> | <right> | <full>

#JoinType:
    <inner> | OuterJoinType() <outer>?

#JoinCondition:
    ::on:: SimpleConditionalExpression()

#JoinSpecification:
    JoinCondition()

#QualifiedJoin:
    TablePrimaryIdentifier() JoinType()? ::join:: TablePrimaryIdentifier() JoinSpecification()

#JoinedTable:
    QualifiedJoin()

#TableIdentifier:
        TablePrimaryIdentifier()
    |   JoinedTable()

#ColumnIdentifier:
        Identifier()
    |   TableIdentifier() ::period:: Identifier()

#ComparisonOperator:
    <op_eq> | <op_neq> | <op_lt> | <op_gt> | <op_lte> | <op_gte>

#AggregateFunction:
    <avg> | <max> | <min> | <sum> | <count>

Argument:
        Literal()
    |   ColumnIdentifier()
    |   FunctionCall()
    |   SimpleArithmeticExpression()

ArgumentsList:
    Argument() (::comma:: Argument())*

#FunctionCall:
    Identifier() ::left_paren:: ArgumentsList()? ::right_paren::

ArithmeticPrimary:
        ColumnIdentifier()
    |   FunctionCall()
    |   Literal()
    |   ::left_paren:: SimpleArithmeticExpression() ::right_paren::

ArithmeticFactor:
    (<op_plus>| <op_minus>)? ArithmeticPrimary()

ArithmeticTerm:
    ArithmeticFactor() ((<op_mul> | <op_div>) ArithmeticFactor())*

SimpleArithmeticExpression:
    ArithmeticTerm() ((<op_plus> | <op_minus>) ArithmeticTerm())*

ArithmeticExpression:
        SimpleArithmeticExpression()
    |   ::left_paren:: Subselect() ::right_paren::

QuantifiedExpression:
    (<all> | <any> | <some>) ::left_paren:: Subselect() ::right_paren::

ComparisonExpression:
    ArithmeticExpression() ComparisonOperator() ( QuantifiedExpression() | ArithmeticExpression() )

#BetweenExpression:
    ArithmeticExpression() <not>? ::between:: ArithmeticExpression() ::and:: ArithmeticExpression()

#LikeExpression:
    StringExpression() <not>? ::like:: StringExpression()

#InExpression:
    ColumnIdentifier() <not>? ::in:: ::left_paren:: Literal() (::comma:: Literal())* ::right_paren::

#NullComparisonExpression:
    (FunctionCall() | ColumnIdentifier()) ::is:: <not>? ::null::

SimpleConditionalExpression:
      ComparisonExpression()
    | BetweenExpression()
    | LikeExpression()
    | InExpression()
    | NullComparisonExpression()

ConditionalPrimary:
    SimpleConditionalExpression() | ::left_paren:: ConditionalExpression() ::right_paren::

#ConditionalFactor:
    <not>? ConditionalPrimary()

ConditionalTerm:
    ConditionalFactor() (<and> ConditionalFactor())*

// 'Case' expression
GeneralCaseExpression:
    ::case:: CaseWhenClause() CaseWhenClause()* ::else:: ScalarExpression() ::end::

CaseWhenClause:
    ::when:: ConditionalExpression() ::then:: ScalarExpression()

SimpleCaseExpression:
    ::case:: CaseOperand() CaseSimpleWhenClause() CaseSimpleWhenClause()* ::else:: ScalarExpression() ::end::

CaseOperand:
    ColumnIdentifier()

CaseSimpleWhenClause:
    ::when:: ScalarExpression() ::then:: ScalarExpression()

// Other expressions
#StringExpression:
    ColumnIdentifier() | string() | FunctionCall()

#ScalarExpression:
        SimpleArithmeticExpression()
    |   ColumnIdentifier()
    |   StringExpression()
    |   boolean()
    |   CaseExpression()

#CaseExpression:
        GeneralCaseExpression()
    |   SimpleCaseExpression()

#AggregateExpression:
    AggregateFunction() ::left_paren:: <distinct>? SimpleArithmeticExpression() ::right_paren::

SimpleSelectClause:
    ::select:: <distinct>? SelectExpression()

FromClause:
    ::from:: TableIdentifier() (::comma:: TableIdentifier())*

#Subselect:
    SimpleSelectClause() FromClause() WhereClause()? GroupByClause()? HavingClause()? OrderByClause()?

#SelectExpression:
    (ScalarExpression() | AggregateExpression() | FunctionCall() | (::left_paren:: Subselect() ::right_paren::) | CaseExpression()) (::as::? Identifier())?

#ConditionalExpression:
    ConditionalTerm() (<or> ConditionalTerm())*

// Clauses
#SelectClause:
    ::select:: <distinct>? SelectExpression() (::comma:: SelectExpression())*

#WhereClause:
    <where> ConditionalExpression()

#OrderByItem:
    (SimpleArithmeticExpression() | ScalarExpression() | FunctionCall()) (<asc> | <desc>)?

#OrderByClause:
    ::order:: ::by:: OrderByItem() (::comma:: OrderByItem())*

#GroupByItem:
    ColumnIdentifier()

#GroupByClause:
    ::group:: ::by:: GroupByItem() (::comma:: GroupByItem())*

#HavingClause:
    ::having:: ConditionalExpression()

#UpdateItem:
    ColumnIdentifier() ::op_eq:: (ArithmeticExpression() | <null>)

#UpdateClause:
    ::update:: TableIdentifier() (::comma:: TableIdentifier())* ::set:: UpdateItem() (::comma:: UpdateItem())*

#DeleteClause:
    ::delete:: ::from:: TableIdentifier() WhereClause()?

// Queries
#SelectQuery:
    SelectClause() FromClause() WhereClause()? GroupByClause()? HavingClause()? OrderByClause()?

#UpdateQuery:
    UpdateClause() WhereClause()?

#DeleteQuery:
    DeleteClause() WhereClause()?

#Query:
        SelectQuery()
     |  UpdateQuery()
     |  DeleteQuery()
