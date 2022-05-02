import Foundation

func stripStringOfSpaces(_ str: String.SubSequence) -> String {
    let result = str.trimmingCharacters(in: .whitespaces)
    return result
}

let outputDir = "/Users/michel/Desktop/Quasicode/Interpreter/Interpreter/AstClasses"

defineAst(outputDir: outputDir, baseName: "AstType", typed: false, types: [
    "AstArrayType   ; contains: AstType",
    "AstClassType   ; name: Token, templateType: AstType?",
    "AstIntType     ; ",
    "AstDoubleType  ; ",
    "AstBooleanType ; ",
    "AstAnyType     ; ",
], additionalVisitorTypes: [
    "String"
])

defineAst(outputDir: outputDir, baseName: "Expr", typed: true, types: [
    "GroupingExpr        ; expression: Expr",
    "LiteralExpr         ; value: Any?",
    "ArrayLiteralExpr    ; values: [Expr]",
    "ThisExpr            ; keyword: Token",
    "SuperExpr           ; keyword: Token, property: Token",
    "VariableExpr        ; name: Token",
    "SubscriptExpr       ; expression: Expr, index: Expr",
    "CallExpr            ; callee: Expr, paren: Token, arguments: [Expr]",
    "GetExpr             ; object: Expr, name: Token",
    "UnaryExpr           ; opr: Token, right: Expr",
    "CastExpr            ; toType: AstType, value: Expr",
    "ArrayAllocationExpr ; contains: AstType, capacity: [Expr]",
    "ClassAllocationExpr ; classType: AstClassType, arguments: [Expr]",
    "BinaryExpr          ; left: Expr, opr: Token, right: Expr",
    "LogicalExpr         ; left: Expr, opr: Token, right: Expr",
    "SetExpr             ; to: Expr, annotation: AstType?, value: Expr",
], additionalVisitorTypes: [
    "String"
])

defineAst(outputDir: outputDir, baseName: "Stmt", typed: false, types: [
    "ClassStmt           ; name: Token, superclass: VariableExpr?, methods: [MethodStmt], staticMethods: [MethodStmt], fields: [ClassFields], staticFields: [ClassFields]",
    "MethodStmt          ; isStatic: Bool, visibilityModifier: VisibilityModifier, function: FunctionStmt",
    "FunctionStmt        ; name: Token, params: [FunctionParams], body: [Stmt]",
    "ExpressionStmt      ; expression: Expr",
    "IfStmt              ; condition: Expr, thenBranch: [Stmt], elseIfBranches: [IfStmt], elseBranch: [Stmt]?",
    "OutputStmt          ; expressions: [Expr]",
    "InputStmt           ; expressions: [Expr]",
    "ReturnStmt          ; keyword: Token, value: Expr",
    "LoopFromStmt        ; variable: Expr, lRange: Expr, rRange: Expr, statements: [Stmt]",
    "WhileStmt           ; expression: Expr, statements: [Stmt]",
    "BreakStmt           ; keyword: Token",
    "ContinueStmt        ; keyword: Token",
], additionalVisitorTypes: [
    "String"
])

func defineAst(outputDir: String, baseName: String, typed: Bool, types: [String], additionalVisitorTypes: [String]) {
    var visitorTypes = additionalVisitorTypes
    visitorTypes.insert("", at: 0)
    
    let path = "\(outputDir)/\(baseName).swift"
    
    var out = ""
    
    out += """
protocol \(baseName) {

"""
    
    for visitorType in visitorTypes {
        out += """
    func accept(visitor: \(baseName)\(visitorType)Visitor)\(visitorType == "" ? "" : " -> \(visitorType)")

"""
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

func defineVisitor(out: inout String, baseName: String, types: [String], visitorTypes: [String]) {
    
    for visitorType in visitorTypes {
        out+="""
    protocol \(baseName)\(visitorType)Visitor {

    """
        for type in types {
            let typeName = stripStringOfSpaces(type.split(separator: ";")[0])
            out+="""
        func visit\(typeName)\(visitorType)(\(baseName.lowercased()): \(typeName)) \(visitorType == "" ? "" : "-> \(visitorType)")

    """
        }
        out+="""
    }


    """
    }
}

func defineType(out: inout String, baseName: String, className: String, fieldList: String, visitorTypes: [String]) {
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
        out+="        self.\(name) = \(name)\n"
    }
    out+="""
    }


"""
    
    // the accept method
    for visitorType in visitorTypes {
        out+="""
    func accept(visitor: \(baseName)\(visitorType)Visitor)\(visitorType == "" ? "" : " -> \(visitorType)") {
        visitor.visit\(className)\(visitorType)(\(baseName.lowercased()): self)
    }

"""
    }
    out+="""
}


"""
    
}
