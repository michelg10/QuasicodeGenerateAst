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

defineAst(outputDir: outputDir, baseName: "AstType", typed: false, includesLocation: true, types: [
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
    .init(type: "QsType", throwable: false)
])

defineAst(outputDir: outputDir, baseName: "Expr", typed: true, includesLocation: true, types: [
    "GroupingExpr        ; expression: Expr",
    "LiteralExpr         ; value: Any?",
    "ArrayLiteralExpr    ; values: [Expr]",
    "StaticClassExpr     ; classType: AstClassType, property: Token",
    "ThisExpr            ; keyword: Token, symbolTableIndex: Int?",
    "SuperExpr           ; keyword: Token, property: Token, symbolTableIndex: Int?",
    "VariableExpr        ; name: Token, symbolTableIndex: Int?",
    "SubscriptExpr       ; expression: Expr, index: Expr",
    "CallExpr            ; callee: Expr, paren: Token, arguments: [Expr]",
    "GetExpr             ; object: Expr, name: Token",
    "UnaryExpr           ; opr: Token, right: Expr",
    "CastExpr            ; toType: AstType, value: Expr",
    "ArrayAllocationExpr ; contains: AstType, capacity: [Expr]",
    "ClassAllocationExpr ; classType: AstClassType, arguments: [Expr]",
    "BinaryExpr          ; left: Expr, opr: Token, right: Expr",
    "LogicalExpr         ; left: Expr, opr: Token, right: Expr",
    "SetExpr             ; to: Expr, annotationColon: Token?, annotation: AstType?, value: Expr, isFirstAssignment: Bool?",
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: nil, throwable: true),
    .init(type: "QsType", throwable: true),
    .init(type: "Expr", throwable: true),
    .init(type: "String", throwable: false),
])

defineAst(outputDir: outputDir, baseName: "Stmt", typed: false, includesLocation: false, types: [
    "ClassStmt           ; keyword: Token, name: Token, symbolTableIndex: Int?, thisSymbolTableIndex: Int?, templateParameters: [Token]?, expandedTemplateParameters: [AstType]?, superclass: AstClassType?, methods: [MethodStmt], staticMethods: [MethodStmt], fields: [ClassField], staticFields: [ClassField]",
    "MethodStmt          ; isStatic: Bool, visibilityModifier: VisibilityModifier, function: FunctionStmt",
    "FunctionStmt        ; keyword: Token, name: Token, symbolTableIndex: Int?, nameSymbolTableIndex: Int?, params: [FunctionParam], annotation: AstType?, body: [Stmt]",
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
    .init(type: "Stmt", throwable: false),
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

struct Variable {
    var name: String
    var type: String
}

func defineAst(outputDir: String, baseName: String, typed: Bool, includesLocation: Bool, types: [String], visitorTypes: [VisitorType]) {
    
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
    if includesLocation {
        out += """
        var startLocation: InterpreterLocation { get set }
        var endLocation: InterpreterLocation { get set }
    
    """
    }
    
    out += """
}


"""
    
    defineVisitor(out: &out, baseName: baseName, types: types, visitorTypes: visitorTypes)
    
    for type in types {
        let typeInformation = type.split(separator: ";")
        let className = stripStringOfSpaces(typeInformation[0])
//        var fields =  + (typed ? ", type: QsType?" : "") + (includesLocation ? ", startLocation: InterpreterLocation, endLocation: InterpreterLocation" : "")
        var fields = stripStringOfSpaces(typeInformation[1]).split(separator: ",")
        var fieldList: [Variable] = []
        for field in fields {
            let strippedField = stripStringOfSpaces(field)
            let separatedField = strippedField.split(separator: ":")
            fieldList.append(.init(name: String(stripStringOfSpaces(separatedField[0])), type: String(stripStringOfSpaces(separatedField[1]))))
        }
        if typed {
            fieldList.append(.init(name: "type", type: "QsType?"))
        }
        if includesLocation {
            fieldList.append(.init(name: "startLocation", type: "InterpreterLocation"))
            fieldList.append(.init(name: "endLocation", type: "InterpreterLocation"))
        }
        
        defineType(out: &out, baseName: baseName, className: String(className), fieldList: fieldList, visitorTypes: visitorTypes)
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

func defineType(out: inout String, baseName: String, className: String, fieldList: [Variable], visitorTypes: [VisitorType]) {
    out+="""
class \(className): \(baseName) {

"""
    // the fields
    for field in fieldList {
        out+="""
    var \(field.name): \(field.type)

"""
    }
    
    // initializer
    let initializerList = fieldList.reduce("", { partialResult, next in
        var result = partialResult
        if partialResult != "" {
            result += ", "
        }
        result+="\(next.name): \(next.type)"
        return result
    })
    out+="""
    
    init(\(initializerList)) {

"""
    for field in fieldList {
        out+="\(indent(2))self.\(field.name) = \(field.name)\n"
    }
    out+="""
    }

"""
    
    // copying initializer
    out+="""
    init(_ objectToCopy: \(className)) {

"""
    for field in fieldList {
        out+="\(indent(2))self.\(field.name) = objectToCopy.\(field.name)\n"
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
