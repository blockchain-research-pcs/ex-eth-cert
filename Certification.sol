pragma solidity ^0.4.2;

// CERTIFICADOS EMITIDOS POR UM CERTIFICADOR
contract EnergyCert {
	address public certifier; // emissor do certificado
	address public owner; // dono do certificado
	uint16 public availableMwh; // quantidade de MWH disponíveis
	uint16 public usedMwh; // quantidade de MWH usados
	
    // Criação de um novo certificado
	function EnergyCert(address _certifier, address _owner, uint16 availableMwh, uint16 _usedMwh) { 
		certifier = _certifier; // é setado na criação e nunca muda
		owner = _owner; // é setado na criação e nunca muda
		availableMwh = availableMwh;
		usedMwh = 0;
	}

    // só continua se requerente for o dono do certificado
	modifier isOwner() {
		require( owner == msg.sender )
			_;
	}

    // transfere MWH disponíveis para usados
	function use(uint16 mwh) isOwner {
		require( mwh <= availableMwh );
		availableMwh -= mwh;
        usedMwh += mwh;
	}
    
    // remove o certificado para a criação de um novo        
    function remove() isOwner { 
            selfdestruct(owner);        
    }
}


// FÁBRICA DE CERTIFICADOS POR UM CERTIFICADOR
contract EnergyCertFactory {
    address public certifier; // criador da fábrica e emissor de novos certificados    
        
    // cria uma fábria de certificados e emite a primeira quantidade de MWH certificada
    function EnergyCertFactory(uint16 mwh) public { 
        certifier = msg.sender; // seta o certificador que nunca muda
        if(mwh > 0) {
            new EnergyCert(certifier, certifier, mwh, 0);
        }        
    }
    // Continua apenas se o requerent for o certificador
    modifier isCertifier() {
        require( certifier == msg.sender )
			_;
    }

    // Emite novo certificado
    function issue(uint mwh) isCertifier {
        if(mwh > 0) {
            new EnergyCert(certifier, certifier, mwh, 0);
        }
    }

    // transferir para alguém uma quantidade de MWH certificada
    function transfer(address certificationAddr, address to, uint16 mwh) public returns (bool success) {        
        EnergyCert cert = EnergyCert(certificationAddr); // referencia do certificado        
        
        if ( cert.owner == msg.sender ) // o dono do certificado deve ser o requerente
            return false;
        
        if ( to == 0x0 ) // o recebedor deve existir
            return false;

        if ( mwh == 0 ) // não tem porque transferir 0
            return false;

        if( mwh > cert.availableMwh ) // o valor a ser transferido deve ser maior que o valor disponível
            return false;

        // guarda os valores do certificado atual
        available = cert.availableMwh; 
        used = cert.usedMwh;

        cert.remove(); // destrói certificado antigo

        new EnergyCert(certifier, msg.sender, available - mwh, used); // cria um certificado novo deduzindo que foi transferido
        new EnergyCert(certifier, to, mwh, 0); // cria um certificado novo para o recebedor com a quantidade indicada

        return true;        
    }    
}
