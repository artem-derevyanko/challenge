SET check_function_bodies = false;
INSERT INTO public.long_tails (id, json_id, tail) VALUES (1, 1, 'best-hello-ever');
INSERT INTO public.long_tails (id, json_id, tail) VALUES (2, 2, 'best-hello-world-ever');
INSERT INTO public.long_tails (id, json_id, tail) VALUES (3, 3, 'best-world-ever');
SELECT pg_catalog.setval('public.long_tails_id_seq', 3, true);
