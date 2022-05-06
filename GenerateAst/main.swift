import Foundation

func stripStringOfSpaces(_ str: String.SubSequence) -> String {
    let result = str.trimmingCharacters(in: .whitespaces)
    return result
}

let outputDir = "/Users/michel/Desktop/Quasicode/Interpreter/Interpreter/AstClasses"

struct VisitorType {
    var type: String?
    var throwable: Bool
}

defineAst(outputDir: outputDir, baseName: "AstType", typed: false, types: [
    "AstArrayType        ; contains: AstType",
    "AstClassType        ; name: Token, templateArguments: [AstType]?",
    "AstTemplateTypeName ; belongingClass: String, name: Token",
    "AstIntType          ; ",
    "AstDoubleType       ; ",
    "AstBooleanType      ; ",
    "AstAnyType          ; ",
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: "String", throwable: false),
    .init(type: "AstType", throwable: true),
])

defineAst(outputDir: outputDir, baseName: "Expr", typed: true, types: [
    "GroupingExpr        ; expression: Expr",
    "LiteralExpr         ; value: Any?",
    "ArrayLiteralExpr    ; values: [Expr]",
    "ThisExpr            ; keyword: Token",
    "SuperExpr           ; keyword: Token, property: Token",
    "VariableExpr        ; name: Token, symbolTableIndex: Int?, runtimeLocation: RuntimeLocation?",
    "SubscriptExpr       ; expression: Expr, index: Expr",
    "CallExpr            ; callee: Expr, paren: Token, arguments: [Expr]",
    "GetExpr             ; object: Expr, name: Token",
    "UnaryExpr           ; opr: Token, right: Expr",
    "CastExpr            ; toType: AstType, value: Expr",
    "ArrayAllocationExpr ; contains: AstType, capacity: [Expr]",
    "ClassAllocationExpr ; classType: AstClassType, arguments: [Expr]",
    "BinaryExpr          ; left: Expr, opr: Token, right: Expr",
    "LogicalExpr         ; left: Expr, opr: Token, right: Expr",
    "SetExpr             ; to: Expr, annotation: AstType?, value: Expr, isFirstAssignment: Bool?",
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: "String", throwable: false),
])

defineAst(outputDir: outputDir, baseName: "Stmt", typed: false, types: [
    "ClassStmt           ; keyword: Token, name: Token, templateParameters: [Token]?, superclass: AstClassType?, methods: [MethodStmt], staticMethods: [MethodStmt], fields: [ClassField], staticFields: [ClassField]",
    "MethodStmt          ; isStatic: Bool, visibilityModifier: VisibilityModifier, function: FunctionStmt",
    "FunctionStmt        ; keyword: Token, name: Token, params: [FunctionParam], annotation: AstType?, body: [Stmt]",
    "ExpressionStmt      ; expression: Expr",
    "IfStmt              ; condition: Expr, thenBranch: [Stmt], elseIfBranches: [IfStmt], elseBranch: [Stmt]?",
    "OutputStmt          ; expressions: [Expr]",
    "InputStmt           ; expressions: [Expr]",
    "ReturnStmt          ; keyword: Token, value: Expr?",
    "LoopFromStmt        ; variable: Expr, lRange: Expr, rRange: Expr, statements: [Stmt]",
    "WhileStmt           ; expression: Expr, statements: [Stmt]",
    "BreakStmt           ; keyword: Token",
    "ContinueStmt        ; keyword: Token",
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: "String", throwable: false),
])

func indent(_ indentLevel: Int = 1) -> String {
    var value = ""
    for _ in 0..<indentLevel {
        value = value + "    "
    }
    return value
}

func acceptFunctionSignature(baseName: String, visitorType: VisitorType) -> String {
    return "func accept(visitor: \(baseName)\(visitorType.type ?? "")\(visitorType.throwable ? "Throw" : "")Visitor)\(visitorType.throwable ? " throws" : "")\(visitorType.type == nil ? "" : " -> \(visitorType.type!)")"
}

func defineAst(outputDir: String, baseName: String, typed: Bool, types: [String], visitorTypes: [VisitorType]) {
    
    let path = "\(outputDir)/\(baseName).swift"
    
    var out = ""
    
    out += """
protocol \(baseName) {

"""
    
    for visitorType in visitorTypes {
        out += indent()+acceptFunctionSignature(baseName: baseName, visitorType: visitorType) + "\n"
    }
    
    if typed {
        out += """
        var type: QsType? { get set }
    
    """
    }
    
    out += """
}


"""
    
    defineVisitor(out: &out, baseName: baseName, types: types, visitorTypes: visitorTypes)
    
    for type in types {
        let typeInformation = type.split(separator: ";")
        let className = stripStringOfSpaces(typeInformation[0])
        let fields = stripStringOfSpaces(typeInformation[1]) + (typed ? ", type: QsType?" : "")
        defineType(out: &out, baseName: baseName, className: String(className), fieldList: String(fields), visitorTypes: visitorTypes)
    }
    
    do {
        try out.write(to: .init(fileURLWithPath: path), atomically: false, encoding: .utf8)
    } catch {
        print(error)
    }
}

func defineVisitor(out: inout String, baseName: String, types: [String], visitorTypes: [VisitorType]) {
    
    for visitorType in visitorTypes {
        out+="""
    protocol \(baseName)\(visitorType.type ?? "")\(visitorType.throwable ? "Throw" : "")Visitor {

    """
        for type in types {
            let typeName = stripStringOfSpaces(type.split(separator: ";")[0])
            out+="""
        func visit\(typeName)\(visitorType.type ?? "")(\(baseName.lowercased()): \(typeName))\(visitorType.throwable ? " throws" : "") \(visitorType.type == nil ? "" : "-> \(visitorType.type!)")

    """
        }
        out+="""
    }


    """
    }
}

func defineType(out: inout String, baseName: String, className: String, fieldList: String, visitorTypes: [VisitorType]) {
    out+="""
class \(className): \(baseName) {

"""
    // the fields
    let fields = fieldList.split(separator: ",")
    for field in fields {
        out+="""
    var \(stripStringOfSpaces(field))

"""
    }
    
    // initializer
    out+="""
    
    init(\(fieldList)) {

"""
    for field in fields {
        let name = stripStringOfSpaces(field.split(separator: ":")[0])
        out+="\(indent(2))self.\(name) = \(name)\n"
    }
    out+="""
    }


"""
    
    // the accept method
    for visitorType in visitorTypes {
        out+="""
    \(acceptFunctionSignature(baseName: baseName, visitorType: visitorType)) {
        \(visitorType.throwable ? "try " : "")visitor.visit\(className)\(visitorType.type ?? "")(\(baseName.lowercased()): self)
    }

"""
    }
    out+="""
}


"""
    
}
