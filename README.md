# Mesterséges intelligencia alapú szoftverek és szolgáltatások fejlesztése - Laborok

![Build docs](https://github.com/viaubxav082/demok/workflows/Build%20docs/badge.svg?branch=main)

[BMEVIAUBXAV082 - Data Engineering a gyakorlatban](https://www.aut.bme.hu/Course/VIAUBXAV082) tárgy előadás demói.

A jegyzetek MkDocs segítségével készülnek és GitHub Pages-en kerülnek publikálásra: <https://viaubxav082.github.io/demok/>

Az MKDocs használatához [a hivatalos dokumentáció](https://squidfunk.github.io/mkdocs-material/creating-your-site/) segítségedre lehet.

## MKDocs tesztelése (Docker-rel)

### Helyi gépen

A futtatáshoz Dockerre van szükség, amihez Windows-on a [Docker Desktop](https://www.docker.com/products/docker-desktop/) egy kényelmes választás.

### Dockerfile elindítása 

A repository tartalmaz egy Dockerfile-t, ami at MKDocs keretrendszer és függőségeinek konfigurációját tartalmazza. Ezt a konténert le kell buildelni, majd futtatni, ami lebuildeli az MKDocs doksinkat, és egyben egy fejlesztési idejű webservert is elindít.

1. Terminál nyitása a repository gyökerébe.
2. Adjuk ki ezt a parancsot Windows (PowerShell), Linux és MacOS esetén:

   ```cmd
   docker build -t mkdocs .
   docker run -it --rm -p 8000:8000 -v ${PWD}:/docs mkdocs
   ```

3. <http://localhost:8000> vagy a codespace átirányított címének megnyitása böngészőből.
4. Markdown szerkesztése és mentése után automatikusan frissül a weboldal.
