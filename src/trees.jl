"""
    JoinTree{T₁, T₂ <: Valuation{T₁}} <: AbstractNode{Int}

A join tree with variables of type `T₁` and factors of type `T₂`.
"""
mutable struct JoinTree{T₁, T₂ <: Valuation{T₁}} <: AbstractNode{Int}
    id::Int
    domain::Vector{T₁}
    factor::T₂
    children::Vector{JoinTree{T₁, T₂}}
    parent::Union{Nothing, JoinTree{T₁, T₂}}
    message_from_parent::Union{Nothing, T₂}
    message_to_parent::Union{Nothing, T₂}

    @doc """
        JoinTree{T₁, T₂}(id, domain, factor) where {T₁, T₂ <: Valuation{T₁}}

    Construct a node in a join tree.
    """
    function JoinTree{T₁, T₂}(id, domain, factor) where {T₁, T₂ <: Valuation{T₁}}
        new{T₁, T₂}(id, domain, factor, JoinTree{T₁, T₂}[], nothing, nothing, nothing)
    end
end

"""
    JoinTree{T₁, T₂}(kb, order) where {T₁, T₂ <: Valuation{T₁}}

Construct a covering join tree for the knowledge base `kb` using the variable elimination
order `order`.
"""
function JoinTree{T₁, T₂}(kb, order) where {T₁, T₂ <: Valuation{T₁}}
    JoinTree{T₁, T₂}(map(ϕ -> convert(T₂, ϕ), kb), order) 
end

function JoinTree{T₁, T₂}(kb::Vector{<:T₂}, order) where {T₁, T₂ <: Valuation{T₁}}
    kb = copy(kb)
    pg = primalgraph(kb)
    ns = JoinTree{T₁, T₂}[]
    l = length(order)
    e = one(T₂)
    for i in 1:l
        X = order[i]
        ϕ = e
        for j in length(kb):-1:1
            if X in domain(kb[j])
                ϕ = combine(ϕ, kb[j])
                deleteat!(kb, j)
            end
        end
        n = JoinTree{T₁, T₂}(i, [X, neighbor_labels(pg, X)...], ϕ)
        for j in length(ns):-1:1
            if X in ns[j].domain
                ns[j].parent = n
                push!(n.children, ns[j])
                deleteat!(ns, j)
            end
        end
        push!(ns, n)
        eliminate!(pg, code_for(pg, X))
    end
    ϕ = e
    for j in length(kb):-1:1
        ϕ = combine(ϕ, kb[j])
    end
    n = JoinTree{T₁, T₂}(l + 1, collect(labels(pg)), ϕ)
    for j in length(ns):-1:1
        ns[j].parent = n
        push!(n.children, ns[j])
    end
    n
end

function ChildIndexing(::Type{<:JoinTree})
    IndexedChildren()
end

function NodeType(::Type{<:JoinTree})
    HasNodeType()
end

function ParentLinks(::Type{<:JoinTree})
    StoredParents()
end

function children(node::JoinTree)
    node.children
end

function nodetype(::Type{T}) where T <: JoinTree
    T
end

function nodevalue(node::JoinTree)
    node.id
end

function parent(node::JoinTree)
    node.parent
end

"""
    solve(jt::JoinTree)
"""
function solve(jt::JoinTree)
    solve(jt, jt.domain)
end

"""
    solve!(jt::JoinTree)
"""
function solve!(jt::JoinTree)
    solve!(jt, jt.domain)
end

"""
    solve(jt::JoinTree, query)

Answer a query.
"""
function solve(jt::T₂, query) where {T₁, T₂ <: JoinTree{<:Any, T₁}}
    x = collect(Set(query))
    for node::T₂ in PreOrderDFS(jt)
        if x ⊆ node.domain        
            factor = node.factor
            for child in node.children
                factor = combine(factor, message_to_parent(child)::T₁)
            end
            if !isroot(node)
                factor = combine(factor, message_from_parent(node)::T₁)
            end
            return duplicate(project(factor, x), query)
        end 
    end
    error("Query not covered by join tree.")
end

"""
    solve!(jt::JoinTree, query)

Answer a query, caching intermediate computations in `jt`.
"""
function solve!(jt::T₂, query) where {T₁, T₂ <: JoinTree{<:Any, T₁}}
    x = collect(Set(query))
    for node::T₂ in PreOrderDFS(jt)
        if x ⊆ node.domain        
            factor = node.factor
            for child in node.children
                factor = combine(factor, message_to_parent!(child)::T₁)
            end
            if !isroot(node)
                factor = combine(factor, message_from_parent!(node)::T₁)
            end
            return duplicate(project(factor, x), query)
        end 
    end
    error("Query not covered by join tree.")
end