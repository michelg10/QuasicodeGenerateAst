import Foundation

func stripStringOfSpaces(_ str: String.SubSequence) -> String {
    let result = str.trimmingCharacters(in: .whitespaces)
    return result
}

let outputDir = "/Users/michel/Desktop/Quasicode/Interpreter/Interpreter/AstClasses"

defineAst(outputDir: outputDir, baseName: "Expr", typed: true, types: [
    "Literal         ; value: Any",
    "This            ; keyword: Token",
    "Super           ; keyword: Token, method: Token",
    "Variable        ; name: Token",
    "Subscript       ; expression: Expr, index: Expr",
    "Call            ; callee: Expr, paren: Token, arguments: [Expr]",
    "Get             ; object: Expr, name: Token",
    "Unary           ; opr: Token, right: Expr",
    "Cast            ; toType: QsType, value: Expr",
    "ArrayAllocation ; contains: QsType, capacity: Expr",
    "ClassAllocation ; classType: QsClass",
    "Binary          ; left: Expr, opr: Token, right: Expr",
    "Set             ; to: Expr, toType: QsType?, value: Expr"
])

defineAst(outputDir: outputDir, baseName: "Stmt", typed: false, types: [
    "Class           ; name: Token, superclass: Variable, methods: [Method], staticMethods: [Method]",
    "Method          ; isStatic: Bool, visibilityModifier: VisibilityModifier, function: Function",
    "Function        ; name: Token, params: [Expr], body: [Stmt]",
    "Expression      ; expression: Expr",
    "If              ; condition: Expr, thenBranch: [Stmt], elseIfBranches: [If], elseBranch: [Stmt]?",
    "Output          ; expressions: [Expr]",
    "Input           ; expressions: [Expr]",
    "Return          ; keyword: Token, value: Expr",
    "For             ; variable: Expr, loopVariable: Expr"
])

func defineAst(outputDir: String, baseName: String, typed: Bool, types: [String]) {
    let path = "\(outputDir)/\(baseName).swift"
    
    var out = ""
    
    out += """
protocol \(baseName) {
    func accept(visitor: \(baseName)Visitor)

"""
    
    if typed {
        out += """
        var type: QsType? { get set }
    
    """
    }
    
    out += """
}


"""
    
    defineVisitor(out: &out, baseName: baseName, types: types)
    
    for type in types {
        let typeInformation = type.split(separator: ";")
        let className = stripStringOfSpaces(typeInformation[0])
        let fields = stripStringOfSpaces(typeInformation[1]) + (typed ? ", type: QsType?" : "")
        defineType(out: &out, baseName: baseName, className: String(className), fieldList: String(fields))
    }
    
    do {
        try out.write(to: .init(fileURLWithPath: path), atomically: false, encoding: .utf8)
    } catch {
        print(error)
    }
}

func defineVisitor(out: inout String, baseName: String, types: [String]) {
    out+="""
protocol \(baseName)Visitor {

"""
    for type in types {
        let typeName = stripStringOfSpaces(type.split(separator: ";")[0])
        out+="""
    func visit\(typeName)\(baseName)(\(baseName.lowercased()): \(typeName))

"""
    }
    out+="""
}


"""
}

func defineType(out: inout String, baseName: String, className: String, fieldList: String) {
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
    out+="""
    func accept(visitor: \(baseName)Visitor) {
        visitor.visit\(className)\(baseName)(\(baseName.lowercased()): self)
    }
}


"""
    
}
