CREATE OR REPLACE FUNCTION public.text_concat ( TEXT, TEXT ) RETURNS TEXT AS $$
SELECT
	CASE	WHEN $1 IS NULL
			THEN $2
		WHEN $2 IS NULL
			THEN $1
		ELSE $1 || ' ' || $2
	END;
$$ LANGUAGE SQL STABLE;

CREATE AGGREGATE public.agg_text (
	sfunc	 = public.text_concat,
	basetype = text,
	stype	 = text
);

CREATE OR REPLACE FUNCTION public.tsvector_concat ( tsvector, tsvector ) RETURNS tsvector AS $$
SELECT
	CASE	WHEN $1 IS NULL
			THEN $2
		WHEN $2 IS NULL
			THEN $1
		ELSE $1 || ' ' || $2
	END;
$$ LANGUAGE SQL STABLE;

CREATE AGGREGATE public.agg_tsvector (
	sfunc	 = public.tsvector_concat,
	basetype = tsvector,
	stype	 = tsvector
);



CREATE OR REPLACE FUNCTION actor.org_unit_descendants ( INT ) RETURNS SETOF actor.org_unit AS $$
	SELECT	a.*
	  FROM	connectby('actor.org_unit','id','parent_ou','name',$1,'100','.')
	  		AS t(keyid text, parent_keyid text, level int, branch text,pos int)
		JOIN actor.org_unit a ON a.id = t.keyid
	  ORDER BY  CASE WHEN a.parent_ou IS NULL THEN 0 ELSE 1 END, a.name;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION actor.org_unit_ancestors ( INT ) RETURNS SETOF actor.org_unit AS $$
	SELECT	a.*
	  FROM	connectby('actor.org_unit','parent_ou','id','name',$1,'100','.')
	  		AS t(keyid text, parent_keyid text, level int, branch text,pos int)
		JOIN actor.org_unit a ON a.id = t.keyid
	  ORDER BY  CASE WHEN a.parent_ou IS NULL THEN 0 ELSE 1 END, a.name;
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION actor.org_unit_descendants ( INT,INT ) RETURNS SETOF actor.org_unit AS $$
	SELECT	a.*
	  FROM	connectby('actor.org_unit','id','parent_ou','name',
	  			(SELECT	x.id
				   FROM	actor.org_unit_ancestors($1) x
				   	JOIN actor.org_unit_type y ON x.ou_type = y.id
				  WHERE	y.depth = $2)
		,'100','.')
	  		AS t(keyid text, parent_keyid text, level int, branch text,pos int)
		JOIN actor.org_unit a ON a.id = t.keyid
	  ORDER BY  CASE WHEN a.parent_ou IS NULL THEN 0 ELSE 1 END, a.name;
$$ LANGUAGE SQL;

